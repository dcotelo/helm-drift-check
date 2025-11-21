#!/bin/bash
# drift-check.sh - Perform Helm chart drift detection

set -euo pipefail

# Global configuration (from environment variables)
readonly SERVICES_CONFIG="${SERVICES_CONFIG:-}"
readonly CHART_PATH="${CHART_PATH:-charts/app}"
readonly SUMMARY_FILE="drift_summary.md"

# Initialize tracking variables
declare -a ACTIVE_SERVICES=()
declare -a ACTIVE_VALUES_FILES=()
declare -a ACTIVE_VERSIONS=()
declare -a MISSING_FILES_WARNINGS=()
declare -a MISSING_VERSION_WARNINGS=()

TOTAL_FILES=0
FILES_WITH_DIFFS=0
OVERALL_DIFF_FOUND=false

# Function to check if a service has valid configuration
check_service_config() {
    local service_name="$1"
    
    # Read values from the shared versions file created by extract-versions script
    local version values_file argo_file
    if [[ -f "service_versions.json" ]]; then
        version=$(jq -r --arg service "$service_name" '.[] | select(.name == $service) | .version // ""' service_versions.json 2>/dev/null || echo "")
        values_file=$(jq -r --arg service "$service_name" '.[] | select(.name == $service) | .values_file // ""' service_versions.json 2>/dev/null || echo "")
        argo_file=$(jq -r --arg service "$service_name" '.[] | select(.name == $service) | .argo_file // ""' service_versions.json 2>/dev/null || echo "")
    else
        echo "  ⚠️  No service_versions.json file found"
        version=""
        values_file=""
        argo_file=""
    fi
    
    echo "  📋 Version: '$version'"
    echo "  📂 Values file: '$values_file'"
    echo "  📄 File exists: $([ -f "$values_file" ] && echo "YES" || echo "NO")"
    
    if [[ -n "$version" ]] && [[ -f "$values_file" ]]; then
        ACTIVE_SERVICES+=("$service_name")
        ACTIVE_VALUES_FILES+=("$values_file")
        ACTIVE_VERSIONS+=("$version")
        echo "  ✅ Service ready for drift check"
        return 0
    elif [[ -n "$version" ]]; then
        echo "  ⚠️  Version found but values file missing"
        MISSING_FILES_WARNINGS+=("**$service_name**: Version \`$version\` found, but values file \`$values_file\` not found")
        return 1
    else
        echo "  ⚠️  No version found in Argo file"
        MISSING_VERSION_WARNINGS+=("**$service_name**: No version found in Argo ApplicationSet file \`$argo_file\`")
        return 1
    fi
}

# Function to process all configured services
process_services() {
    echo "🔍 Processing configured services..."
    
    # Read all services from the JSON file created by extract-versions
    local services_count
    services_count=$(jq -r '. | length' service_versions.json)
    
    for ((i = 0; i < services_count; i++)); do
        local service_data
        service_data=$(jq -r ".[$i]" service_versions.json)
        
        local service_name
        service_name=$(echo "$service_data" | jq -r '.name')
        
        echo ""
        echo "🔍 Processing service: $service_name"
        check_service_config "$service_name"
    done
    
    TOTAL_FILES=${#ACTIVE_SERVICES[@]}
    
    echo ""
    echo "📊 Service processing summary:"
    echo "  - Active services: $TOTAL_FILES (${ACTIVE_SERVICES[*]:-none})"
    echo "  - Missing file warnings: ${#MISSING_FILES_WARNINGS[@]}"
    echo "  - Missing version warnings: ${#MISSING_VERSION_WARNINGS[@]}"
}

# Function to perform drift check for a single service
check_service_drift() {
    local service_name="$1"
    local values_file="$2"
    local prev_tag="$3"
    
    echo "🔍 Checking drift for: $service_name ($values_file) - comparing $prev_tag → HEAD"
    
    # Validate values file exists
    if [[ ! -f "$values_file" ]]; then
        echo "⚠️  Values file not found: $values_file"
        return 1
    fi
    
    # Create clean output directories
    local output_dir="helm-output-$(basename "$values_file" .yaml)"
    rm -rf "$output_dir"
    mkdir -p "$output_dir/prev" "$output_dir/curr"
    
    # Extract previous version from git
    echo "📥 Extracting previous version from tag: $prev_tag"
    if ! git archive "$prev_tag" "$CHART_PATH" | tar -x -C "$output_dir/prev/" 2>/dev/null; then
        echo "❌ Failed to extract previous version from tag: $prev_tag"
        rm -rf "$output_dir"
        return 1
    fi
    
    # Render Helm templates for previous version
    local prev_output="$output_dir/prev-$(basename "$values_file" .yaml).yaml"
    if ! helm template app "$output_dir/prev/$CHART_PATH" -f "$values_file" > "$prev_output" 2>&1; then
        echo "❌ Failed to render previous version Helm template"
        rm -rf "$output_dir"
        return 1
    fi
    
    # Render Helm templates for current version
    local curr_output="$output_dir/curr-$(basename "$values_file" .yaml).yaml"
    if ! helm template app "$CHART_PATH" -f "$values_file" > "$curr_output" 2>&1; then
        echo "❌ Failed to render current version Helm template"
        rm -rf "$output_dir"
        return 1
    fi
    
    # Compare with dyff
    local diff_file="$output_dir/diff.txt"
    echo "🔄 Running dyff comparison..."
    
    # Run dyff comparison (without exit codes to prevent script failure)
    if dyff between "$prev_output" "$curr_output" --omit-header > "$diff_file" 2>&1; then
        local has_diff=false
    else
        local has_diff=true
    fi
    
    # Check if meaningful differences exist
    if [[ ! -s "$diff_file" ]] || ! grep -q "." "$diff_file" 2>/dev/null; then
        echo "✅ No differences found for $service_name"
        
        cat >> "$SUMMARY_FILE" << EOF
### ✅ $service_name
**Deployed version:** \`$prev_tag\` | **Values file:** \`$(basename "$values_file")\`

No differences detected

EOF
    else
        echo "⚠️ Differences found for $service_name"
        ((FILES_WITH_DIFFS++))
        OVERALL_DIFF_FOUND=true
        
        cat >> "$SUMMARY_FILE" << EOF
### ⚠️ $service_name
**Deployed version:** \`$prev_tag\` | **Values file:** \`$(basename "$values_file")\`

*Changes detected for review and confirmation*
\`\`\`diff
$(cat "$diff_file")
\`\`\`

EOF
    fi
    
    # Clean up
    rm -rf "$output_dir"
    return 0
}

# Function to write summary header
write_summary_header() {
    cat > "$SUMMARY_FILE" << EOF
## 📊 Helm Chart Drift Check Results

*Automated check for awareness - changes are not considered failures*

EOF

    # Build comparison summary with actual versions
    if [[ ${#ACTIVE_SERVICES[@]} -gt 0 ]]; then
        local comparison_summary=""
        for i in "${!ACTIVE_SERVICES[@]}"; do
            local service_name="${ACTIVE_SERVICES[$i]}"
            local version="${ACTIVE_VERSIONS[$i]}"
            if [[ $i -eq 0 ]]; then
                comparison_summary="${service_name}: \`${version}\`"
            else
                comparison_summary="${comparison_summary}, ${service_name}: \`${version}\`"
            fi
        done
        
        echo "**Comparison:** ${comparison_summary} → \`HEAD\`" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
    fi
}

# Function to write warnings section
write_warnings_section() {
    if [[ ${#MISSING_FILES_WARNINGS[@]} -gt 0 ]] || [[ ${#MISSING_VERSION_WARNINGS[@]} -gt 0 ]]; then
        echo "" >> "$SUMMARY_FILE"
        echo "## ⚠️ Configuration Warnings" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        
        if [[ ${#MISSING_VERSION_WARNINGS[@]} -gt 0 ]]; then
            echo "### Missing Versions" >> "$SUMMARY_FILE"
            for warning in "${MISSING_VERSION_WARNINGS[@]}"; do
                echo "- $warning" >> "$SUMMARY_FILE"
            done
            echo "" >> "$SUMMARY_FILE"
        fi
        
        if [[ ${#MISSING_FILES_WARNINGS[@]} -gt 0 ]]; then
            echo "### Missing Values Files" >> "$SUMMARY_FILE"
            for warning in "${MISSING_FILES_WARNINGS[@]}"; do
                echo "- $warning" >> "$SUMMARY_FILE"
            done
            echo "" >> "$SUMMARY_FILE"
        fi
        
        echo "*Please check the Argo ApplicationSet files and values file paths in the service configurations.*" >> "$SUMMARY_FILE"
    fi
}

# Function to write summary footer
write_summary_footer() {
    echo "" >> "$SUMMARY_FILE"
    echo "---" >> "$SUMMARY_FILE"
    
    if [[ $FILES_WITH_DIFFS -gt 0 ]]; then
        cat >> "$SUMMARY_FILE" << EOF
**📋 Summary:** $FILES_WITH_DIFFS out of $TOTAL_FILES files have changes for review

*This check is for awareness only. Please review the changes above to ensure they are intentional.*
EOF
    else
        echo "**✅ Summary:** All $TOTAL_FILES files match the previous version - no changes detected" >> "$SUMMARY_FILE"
    fi
}

# Main execution function
main() {
    echo "🚀 Starting Helm chart drift check..."
    
    # Validate configuration is provided
    if [[ -z "$SERVICES_CONFIG" ]]; then
        echo "❌ SERVICES_CONFIG environment variable is empty"
        exit 1
    fi
    
    # Check if we have service versions JSON file
    if [[ ! -f "service_versions.json" ]]; then
        echo "❌ No service_versions.json file found from extract-versions step"
        cat > "$SUMMARY_FILE" << EOF
## 📊 Helm Chart Drift Check Results

*Automated check for awareness - changes are not considered failures*

⚠️ **No service versions found**

Unable to find chart versions in Argo ApplicationSet files or git tags.
Drift checking will be available once versions are properly configured.
EOF
        echo "diff_found=false" >> "$GITHUB_OUTPUT"
        echo "files_with_diffs=0" >> "$GITHUB_OUTPUT"
        echo "total_files=0" >> "$GITHUB_OUTPUT"
        echo "summary_file=$SUMMARY_FILE" >> "$GITHUB_OUTPUT"
        return 0
    fi
    
    # Check if JSON file has any services with versions
    local services_with_versions
    services_with_versions=$(jq -r '[.[] | select(.version != "")] | length' service_versions.json 2>/dev/null || echo "0")
    if [[ "$services_with_versions" -eq 0 ]]; then
        echo "⚠️  No services with valid versions found in service_versions.json"
        cat > "$SUMMARY_FILE" << EOF
## 📊 Helm Chart Drift Check Results

*Automated check for awareness - changes are not considered failures*

⚠️ **No service versions found**

Unable to extract chart versions from Argo ApplicationSet files.
Please check the Argo file paths and targetRevision fields.
EOF
        echo "diff_found=false" >> "$GITHUB_OUTPUT"
        echo "files_with_diffs=0" >> "$GITHUB_OUTPUT"
        echo "total_files=0" >> "$GITHUB_OUTPUT"
        echo "summary_file=$SUMMARY_FILE" >> "$GITHUB_OUTPUT"
        return 0
    fi
    
    # Process all services to determine active ones
    process_services
    
    # Write summary header
    write_summary_header
    
    # Perform drift checks for active services
    if [[ ${#ACTIVE_SERVICES[@]} -gt 0 ]]; then
        for i in "${!ACTIVE_SERVICES[@]}"; do
            local service_name="${ACTIVE_SERVICES[$i]}"
            local values_file="${ACTIVE_VALUES_FILES[$i]}"
            local prev_tag="${ACTIVE_VERSIONS[$i]}"
            
            echo ""
            if ! check_service_drift "$service_name" "$values_file" "$prev_tag"; then
                echo "⚠️  Drift check failed for $service_name, skipping..."
                continue
            fi
        done
    else
        echo "⚠️  No active services found for drift checking"
    fi
    
    # Write warnings section
    write_warnings_section
    
    # Write summary footer
    write_summary_footer
    
    # Set outputs
    echo "diff_found=$OVERALL_DIFF_FOUND" >> "$GITHUB_OUTPUT"
    echo "files_with_diffs=$FILES_WITH_DIFFS" >> "$GITHUB_OUTPUT" 
    echo "total_files=$TOTAL_FILES" >> "$GITHUB_OUTPUT"
    echo "summary_file=$SUMMARY_FILE" >> "$GITHUB_OUTPUT"
    
    echo ""
    echo "✅ Drift check completed successfully"
    echo "   - Files checked: $TOTAL_FILES"
    echo "   - Files with diffs: $FILES_WITH_DIFFS"
    echo "   - Overall drift found: $OVERALL_DIFF_FOUND"
}

# Execute main function
main
