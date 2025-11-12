#!/bin/bash
set -e

# Usage function
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Install Neo4j MCP Server for Claude Code with configurable connection settings.

OPTIONS:
    --neo4j-auth AUTH          Neo4j authentication (format: username/password)
                               Default: neo4j/neo4j
    --neo4j-uri URI            Neo4j connection URI
                               Default: bolt://localhost:7687
    --neo4j-database DATABASE  Neo4j database name
                               Default: neo4j
    -h, --help                 Show this help message

EXAMPLES:
    $0
    $0 --neo4j-auth neo4j/mypassword
    $0 --neo4j-uri bolt://neo4j.example.com:7687 --neo4j-auth neo4j/secret

ENVIRONMENT VARIABLES:
    NEO4J_AUTH                 Can be set instead of using --neo4j-auth
    NEO4J_URI                  Can be set instead of using --neo4j-uri
    NEO4J_DATABASE             Can be set instead of using --neo4j-database

Priority: Command-line options > Environment variables > Interactive prompts > Defaults

EOF
    exit 0
}

# Parse command-line options
NEO4J_AUTH_ARG=""
NEO4J_URI_ARG=""
NEO4J_DATABASE_ARG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --neo4j-auth)
            NEO4J_AUTH_ARG="$2"
            shift 2
            ;;
        --neo4j-uri)
            NEO4J_URI_ARG="$2"
            shift 2
            ;;
        --neo4j-database)
            NEO4J_DATABASE_ARG="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

echo "🚀 Installing Neo4j MCP Server for Claude Code..."
echo ""

# Determine Neo4j configuration values
# Priority: Command-line args > Environment variables > Interactive prompt > Defaults

# NEO4J_AUTH
if [ -n "$NEO4J_AUTH_ARG" ]; then
    NEO4J_AUTH="$NEO4J_AUTH_ARG"
    echo "✓ Using NEO4J_AUTH from command-line argument"
elif [ -n "$NEO4J_AUTH" ]; then
    echo "✓ Using NEO4J_AUTH from environment variable"
else
    read -p "Enter Neo4j authentication (username/password) [neo4j/neo4j]: " NEO4J_AUTH
    NEO4J_AUTH="${NEO4J_AUTH:-neo4j/neo4j}"
fi

# NEO4J_URI
if [ -n "$NEO4J_URI_ARG" ]; then
    NEO4J_URI="$NEO4J_URI_ARG"
    echo "✓ Using NEO4J_URI from command-line argument"
elif [ -n "$NEO4J_URI" ]; then
    echo "✓ Using NEO4J_URI from environment variable"
else
    read -p "Enter Neo4j URI [bolt://localhost:7687]: " NEO4J_URI
    NEO4J_URI="${NEO4J_URI:-bolt://localhost:7687}"
fi

# NEO4J_DATABASE
if [ -n "$NEO4J_DATABASE_ARG" ]; then
    NEO4J_DATABASE="$NEO4J_DATABASE_ARG"
    echo "✓ Using NEO4J_DATABASE from command-line argument"
elif [ -n "$NEO4J_DATABASE" ]; then
    echo "✓ Using NEO4J_DATABASE from environment variable"
else
    read -p "Enter Neo4j database name [neo4j]: " NEO4J_DATABASE
    NEO4J_DATABASE="${NEO4J_DATABASE:-neo4j}"
fi

echo ""
echo "📝 Configuration:"
echo "   NEO4J_URI: $NEO4J_URI"
echo "   NEO4J_AUTH: ${NEO4J_AUTH%%/*}/****"
echo "   NEO4J_DATABASE: $NEO4J_DATABASE"
echo ""

# Set paths
SERVER_PATH="$(pwd)"
INSTALL_METHOD=""

# Check for nvm and npm
if command -v nvm &> /dev/null || [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "✓ nvm detected"

    # Load nvm if not already loaded
    if ! command -v nvm &> /dev/null; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi

    # Use .nvmrc if it exists, otherwise use current/latest LTS
    if [ -f ".nvmrc" ]; then
        echo "📦 Installing Node.js version from .nvmrc..."
        nvm install
        nvm use
    else
        echo "📦 Using current Node.js version..."
        if ! command -v node &> /dev/null; then
            echo "📦 Installing Node.js LTS..."
            nvm install --lts
            nvm use --lts
        fi
    fi

    # Build with npm
    echo "📦 Building with npm..."
    npm install
    npm run build

    INSTALL_METHOD="npm"
    echo "✅ Built successfully with npm"

elif command -v npm &> /dev/null && command -v node &> /dev/null; then
    echo "✓ npm and node detected (without nvm)"

    # Build with npm
    echo "📦 Building with npm..."
    npm install
    npm run build

    INSTALL_METHOD="npm"
    echo "✅ Built successfully with npm"

elif command -v docker &> /dev/null; then
    echo "⚠️  npm/nvm not found, falling back to Docker"

    # Build Docker image
    echo "📦 Building Docker image..."
    docker build -t mcp-neo4j-claude-code-server .

    INSTALL_METHOD="docker"
    echo "✅ Built successfully with Docker"

else
    echo "❌ Neither npm/node nor Docker is available"
    echo "Please install Node.js (https://nodejs.org) or Docker (https://docker.com)"
    exit 1
fi

# Configure Claude Code MCP server
echo "⚙️  Configuring Claude Code MCP settings..."

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "❌ claude CLI not found. Please install Claude Code first."
    echo "   Visit: https://claude.ai/download"
    exit 1
fi

# Remove existing neo4j server if present
claude mcp remove neo4j -s user 2>/dev/null || true

# Add MCP server based on install method
if [ "$INSTALL_METHOD" == "npm" ]; then
    claude mcp add -s user -t stdio neo4j \
        -e NEO4J_URI="$NEO4J_URI" \
        -e NEO4J_AUTH="$NEO4J_AUTH" \
        -e NEO4J_DATABASE="$NEO4J_DATABASE" \
        -- node "$SERVER_PATH/build/index.js"
else
    claude mcp add -s user -t stdio neo4j \
        -e NEO4J_URI="$NEO4J_URI" \
        -e NEO4J_AUTH="$NEO4J_AUTH" \
        -e NEO4J_DATABASE="$NEO4J_DATABASE" \
        -- docker run -i --rm --network=host \
        -e "NEO4J_URI=$NEO4J_URI" \
        -e "NEO4J_AUTH=$NEO4J_AUTH" \
        -e "NEO4J_DATABASE=$NEO4J_DATABASE" \
        mcp-neo4j-claude-code-server
fi

if [ $? -ne 0 ]; then
    echo "❌ Failed to configure MCP server"
    exit 1
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "📍 Configuration: User scope (available in all your projects)"
echo "🔧 Install method: $INSTALL_METHOD"
echo ""
echo "🔄 Next steps:"
echo "   1. Ensure Neo4j is running at $NEO4J_URI"
echo "   2. Verify with: claude mcp list"
echo "   3. Test with: 'Show me all nodes in the database'"
echo ""
echo "⚙️  To manage the MCP server:"
echo "   • View config: claude mcp get neo4j"
echo "   • Remove: claude mcp remove neo4j -s user"
echo "   • Reconfigure: Run this installer again with different options"
echo ""
echo "📝 Run '$0 --help' to see all configuration options"
echo ""
