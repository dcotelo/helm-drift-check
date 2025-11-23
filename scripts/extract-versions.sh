#!/bin/bash
# extract-versions.sh - Extract service versions from Argo ApplicationSet files

set -euo pipefail

# Global configuration (from environment variables)
readonly SERVICES_CONFIG="${SERVICES_CONFIG:-}"

# Initialize tracking arrays
declare -a SERVICE_NAMES=()
declare -a SERVICE_VERSIONS=()
declare -a SERVICE_VALUES_FILES=()
declare -a SERVICE_ARGO_FILES=()

# Function to extract version from Argo ApplicationSet file
extract_service_version() {
    local argo_file="$1"
    
    if [[ ! -f "$argo_file" ]]; then
        return 1
    fi
    
    # Extract targetRevision from Helm chart source (looks for common patterns)
    # Try multiple patterns to support different repository naming conventions
    local version=""
    
    # Pattern 1: Look for targetRevision near helm-charts or chart repository
    version=$(grep -A 10 "repoURL.*helm-charts" "$argo_file" | \
        grep "targetRevision:" | \
        head -n1 | \
        sed 's/.*targetRevision: *//g' | \
        tr -d ' \t\r\n' || echo "")
    
    # Pattern 2: If not found, try generic approach - first targetRevision in the file
    if [[ -z "$version" ]]; then
        version=$(grep "targetRevision:" "$argo_file" | \
            head -n1 | \
            sed 's/.*targetRevision: *//g' | \
            tr -d ' \t\r\n' || echo "")
    fi
    
    echo "$version"
}

# Function to validate and normalize file paths
normalize_path() {
    local path="$1"
    # Remove leading/trailing spaces and resolve relative paths
    echo "$path" | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g'
}

# Main extraction logic
main() {
    echo "🔍 Extracting service versions from configuration..."
    
    # Validate configuration is provided
    if [[ -z "$SERVICES_CONFIG" ]]; then
        echo "❌ SERVICES_CONFIG environment variable is empty"
        exit 1
    fi
    
    echo "📋 Services config received:"
    echo "$SERVICES_CONFIG"
    
    # Validate JSON and parse services configuration
    local services_count
    if ! services_count=$(echo "$SERVICES_CONFIG" | jq -r '. | length' 2>/dev/null); then
        echo "❌ Failed to parse SERVICES_CONFIG as JSON"
        echo "Raw config: $SERVICES_CONFIG"
        exit 1
    fi
    
    echo "📋 Found $services_count service(s) configured"
    
    for ((i = 0; i < services_count; i++)); do
        local service_data
        service_data=$(echo "$SERVICES_CONFIG" | jq -r ".[$i]")
        
        local service_name argo_file values_file
        service_name=$(echo "$service_data" | jq -r '.name')
        argo_file=$(normalize_path "$(echo "$service_data" | jq -r '.argo_file')")
        values_file=$(normalize_path "$(echo "$service_data" | jq -r '.values_file')")
        
        echo ""
        echo "🔍 Processing service: $service_name"
        echo "  📁 Argo file: $argo_file"
        echo "  📄 Values file: $values_file"
        
        # Extract version
        local version
        if version=$(extract_service_version "$argo_file"); then
            if [[ -n "$version" ]]; then
                echo "  ✅ Version found: $version"
                SERVICE_NAMES+=("$service_name")
                SERVICE_VERSIONS+=("$version")
                SERVICE_VALUES_FILES+=("$values_file")
                SERVICE_ARGO_FILES+=("$argo_file")
                
                # Output to GitHub Actions
                echo "${service_name}_version=$version" >> "$GITHUB_OUTPUT"
                echo "${service_name}_values_file=$values_file" >> "$GITHUB_OUTPUT"
                echo "${service_name}_argo_file=$argo_file" >> "$GITHUB_OUTPUT"
            else
                echo "  ⚠️  Version extraction returned empty result"
                echo "${service_name}_version=" >> "$GITHUB_OUTPUT"
                echo "${service_name}_values_file=$values_file" >> "$GITHUB_OUTPUT"
                echo "${service_name}_argo_file=$argo_file" >> "$GITHUB_OUTPUT"
            fi
        else
            echo "  ❌ Failed to extract version (file not found or parsing error)"
            echo "${service_name}_version=" >> "$GITHUB_OUTPUT"
            echo "${service_name}_values_file=$values_file" >> "$GITHUB_OUTPUT"
            echo "${service_name}_argo_file=$argo_file" >> "$GITHUB_OUTPUT"
        fi
    done
    
    # Check if we found any versions
    if [[ ${#SERVICE_NAMES[@]} -eq 0 ]]; then
        echo ""
        echo "⚠️  No service versions found - checking for fallback git tags..."
        
        local fallback_tag
        if fallback_tag=$(git tag -l 'v*' --sort=-version:refname | head -n1); then
            if [[ -n "$fallback_tag" ]]; then
                echo "📌 Found fallback tag: $fallback_tag"
                echo "fallback_tag=$fallback_tag" >> "$GITHUB_OUTPUT"
                echo "no_versions=false" >> "$GITHUB_OUTPUT"
            else
                echo "❌ No git tags found either"
                echo "no_versions=true" >> "$GITHUB_OUTPUT"
            fi
        else
            echo "❌ Git tag check failed"
            echo "no_versions=true" >> "$GITHUB_OUTPUT"
        fi
    else
        echo ""
        echo "✅ Successfully extracted ${#SERVICE_NAMES[@]} service version(s)"
        echo "no_versions=false" >> "$GITHUB_OUTPUT"
    fi
    
    # Create JSON file with all service information for drift-check script
    echo "📄 Creating service_versions.json for drift-check script..."
    echo "[]" > service_versions.json
    
    for ((i = 0; i < ${#SERVICE_NAMES[@]}; i++)); do
        local service_entry
        service_entry=$(jq -n \
            --arg name "${SERVICE_NAMES[$i]}" \
            --arg version "${SERVICE_VERSIONS[$i]}" \
            --arg values_file "${SERVICE_VALUES_FILES[$i]}" \
            --arg argo_file "${SERVICE_ARGO_FILES[$i]}" \
            '{
                name: $name,
                version: $version,
                values_file: $values_file,
                argo_file: $argo_file
            }')
        
        # Add to the JSON array
        local temp_json
        temp_json=$(jq --argjson entry "$service_entry" '. += [$entry]' service_versions.json)
        echo "$temp_json" > service_versions.json
    done
    
    echo "📋 Created service_versions.json with $(jq '. | length' service_versions.json) services"
    
    # Output summary information
    echo "services_found=${#SERVICE_NAMES[@]}" >> "$GITHUB_OUTPUT"
    echo "curr_tag=$GITHUB_SHA" >> "$GITHUB_OUTPUT"
}

# Execute main function
main
