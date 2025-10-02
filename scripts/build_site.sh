#!/bin/bash

# Sandman Jekyll Site Build Script
# This script handles building and deploying the Sandman website

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="$(cd "$SCRIPT_DIR/../../sandman-docs/docs" && pwd)"
BUILD_DIR="${SITE_DIR}/_site"
JEKYLL_ENV="${JEKYLL_ENV:-production}"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Ruby version
check_ruby_version() {
    if ! command_exists ruby; then
        print_error "Ruby is not installed. Please install Ruby 2.7 or higher."
        exit 1
    fi

    local ruby_version=$(ruby -v | cut -d' ' -f2 | cut -d'.' -f1,2)
    local required_version="2.7"

    if [ "$(printf '%s\n' "$required_version" "$ruby_version" | sort -V | head -n1)" != "$required_version" ]; then
        print_error "Ruby version $ruby_version is too old. Please install Ruby $required_version or higher."
        exit 1
    fi

    print_success "Ruby version $ruby_version is compatible"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing Ruby dependencies..."
    cd "$SITE_DIR"

    if ! command_exists bundle; then
        print_status "Installing Bundler..."
        gem install bundler
    fi

    bundle install --quiet
    print_success "Dependencies installed successfully"
}

# Function to clean previous builds
clean_build() {
    print_status "Cleaning previous build..."
    cd "$SITE_DIR"

    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_success "Cleaned _site directory"
    fi

    if [ -d ".jekyll-cache" ]; then
        rm -rf ".jekyll-cache"
        print_success "Cleaned Jekyll cache"
    fi
}

# Function to build the site
build_site() {
    print_status "Building Jekyll site for $JEKYLL_ENV environment..."
    cd "$SITE_DIR"

    JEKYLL_ENV="$JEKYLL_ENV" bundle exec jekyll build --verbose

    if [ $? -eq 0 ]; then
        print_success "Site built successfully in $BUILD_DIR"
    else
        print_error "Site build failed"
        exit 1
    fi
}

# Function to serve the site locally
serve_site() {
    print_status "Starting Jekyll development server..."
    cd "$SITE_DIR"

    print_status "Site will be available at http://localhost:7991"
    print_status "Press Ctrl+C to stop the server"

    JEKYLL_ENV="development" bundle exec jekyll serve --livereload --open-url --port 7991
}

# Function to generate API documentation
generate_api_docs() {
    print_status "Generating API documentation from JSON definitions..."

    local api_docs_script="$SCRIPT_DIR/build_api_docs.rb"

    if [ ! -f "$api_docs_script" ]; then
        print_error "API docs generator script not found: $api_docs_script"
        exit 1
    fi

    local api_definitions_file="$SCRIPT_DIR/../priv/api_definitions.json"
    if [ ! -f "$api_definitions_file" ]; then
        print_error "API definitions file not found: $api_definitions_file"
        print_status "Please ensure the JSON definitions file exists in priv/api_definitions.json"
        exit 1
    fi

    ruby "$api_docs_script"

    if [ $? -eq 0 ]; then
        print_success "API documentation generated successfully"
    else
        print_error "Failed to generate API documentation"
        exit 1
    fi
}

# Function to validate the built site
validate_build() {
    print_status "Validating built site..."

    # Check if critical files exist (Jekyll creates directories with index.html)
    local critical_files=(
        "index.html"
        "downloads/index.html"
        "blog/index.html"
        "docs/index.html"
        "docs/api/index.html"
        "docs/examples/index.html"
        "assets/css/main.css"
        "feed.xml"
        "sitemap.xml"
    )

    local missing_files=()

    for file in "${critical_files[@]}"; do
        if [ ! -f "$BUILD_DIR/$file" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -eq 0 ]; then
        print_success "All critical files are present"
    else
        print_warning "Missing files detected:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
    fi

    # Check site size
    local site_size=$(du -sh "$BUILD_DIR" | cut -f1)
    print_status "Site size: $site_size"
}

# Function to deploy to GitHub Pages
deploy_github_pages() {
    print_status "Deploying to GitHub Pages..."
    cd "$SITE_DIR"

    if ! command_exists git; then
        print_error "Git is not installed. Cannot deploy to GitHub Pages."
        exit 1
    fi

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository. Cannot deploy to GitHub Pages."
        exit 1
    fi

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_warning "You have uncommitted changes. Commit them first."
        git status --porcelain
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Build for production
    JEKYLL_ENV="production" build_site

    # Deploy using gh-pages branch or GitHub Actions
    if command_exists gh; then
        print_status "Using GitHub CLI to deploy..."
        gh workflow run deploy.yml
        print_success "Deployment triggered via GitHub Actions"
    else
        print_status "Consider setting up GitHub Actions for automatic deployment"
        print_status "Or install GitHub CLI with: brew install gh"
    fi
}

# Function to deploy to Netlify
deploy_netlify() {
    print_status "Deploying to Netlify..."
    cd "$SITE_DIR"

    if ! command_exists netlify; then
        print_error "Netlify CLI is not installed."
        print_status "Install it with: npm install -g netlify-cli"
        exit 1
    fi

    # Build for production
    JEKYLL_ENV="production" build_site

    # Deploy to Netlify
    netlify deploy --prod --dir="$BUILD_DIR"

    if [ $? -eq 0 ]; then
        print_success "Successfully deployed to Netlify"
    else
        print_error "Netlify deployment failed"
        exit 1
    fi
}

# Function to run tests
run_tests() {
    print_status "Running site tests..."

    # Build the site first
    JEKYLL_ENV="test" build_site

    # Test 1: Check for broken internal links
    if command_exists htmlproofer; then
        print_status "Checking for broken links..."
        htmlproofer "$BUILD_DIR" --check-html --check-img-http --disable-external
    else
        print_warning "htmlproofer not installed. Skipping link checking."
        print_status "Install with: gem install html-proofer"
    fi

    # Test 2: Validate HTML
    if command_exists tidy; then
        print_status "Validating HTML..."
        find "$BUILD_DIR" -name "*.html" -exec tidy -q -e {} \; 2>/dev/null || true
    fi

    # Test 3: Check file sizes
    print_status "Checking asset sizes..."
    find "$BUILD_DIR/assets" -name "*.css" -o -name "*.js" | while read -r file; do
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unknown")
        if [ "$size" != "unknown" ] && [ "$size" -gt 500000 ]; then
            print_warning "Large asset detected: $(basename "$file") (${size} bytes)"
        fi
    done

    print_success "Tests completed"
}

# Function to show help
show_help() {
    cat << EOF
Sandman Jekyll Site Build Script

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    build       Build the site for production
    serve       Start development server with live reload
    clean       Clean build artifacts
    test        Run tests on the built site
    deploy      Deploy to hosting service
    install     Install dependencies
    docs        Generate API documentation from definitions
    help        Show this help message

DEPLOYMENT TARGETS:
    github      Deploy to GitHub Pages
    netlify     Deploy to Netlify

ENVIRONMENT VARIABLES:
    JEKYLL_ENV  Set Jekyll environment (development, production, test)

EXAMPLES:
    $0 install                  # Install dependencies
    $0 serve                    # Start development server
    $0 build                    # Build for production
    $0 test                     # Run tests
    $0 deploy github            # Deploy to GitHub Pages
    $0 deploy netlify           # Deploy to Netlify

    JEKYLL_ENV=development $0 build  # Build in development mode

EOF
}

# Main script logic
main() {
    case "${1:-}" in
        "install")
            check_ruby_version
            install_dependencies
            ;;
        "clean")
            clean_build
            ;;
        "build")
            check_ruby_version
            clean_build
            build_site
            validate_build
            ;;
        "serve")
            check_ruby_version
            serve_site
            ;;
        "docs")
            generate_api_docs
            ;;
        "test")
            check_ruby_version
            run_tests
            ;;
        "deploy")
            case "${2:-}" in
                "github")
                    deploy_github_pages
                    ;;
                "netlify")
                    deploy_netlify
                    ;;
                *)
                    print_error "Please specify deployment target: github or netlify"
                    echo "Usage: $0 deploy [github|netlify]"
                    exit 1
                    ;;
            esac
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            print_status "Building Sandman Jekyll site..."
            check_ruby_version
            install_dependencies
            clean_build
            build_site
            validate_build
            print_success "Build completed successfully!"
            print_status "Run '$0 serve' to start development server"
            print_status "Run '$0 help' for more options"
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run the main function with all arguments
main "$@"
