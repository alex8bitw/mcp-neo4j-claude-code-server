# Installation Guide for Claude Code

This guide walks you through installing and configuring the Neo4j MCP server for Claude Code CLI.

## Prerequisites

- **Neo4j 5.x** running at `bolt://localhost:7687` (or custom URI)
- **Node.js 18+** installed
- **Claude Code CLI** installed and configured

## Installation

1. Clone or navigate to the mcp-neo4j-claude-code-server directory:
```bash
cd mcp-neo4j-claude-code-server
```

2. Install dependencies:
```bash
npm install
```

3. Build the project:
```bash
npm run build
```

This will compile TypeScript to JavaScript in the `build/` directory.

## Configuration

### Configure Claude Code MCP Server

Add the Neo4j MCP server to your Claude Code user configuration using the `claude mcp add` command:

```bash
cd /path/to/mcp-neo4j-claude-code-server
claude mcp add -s user -t stdio neo4j \
  -e NEO4J_URI=bolt://localhost:7687 \
  -e NEO4J_AUTH=neo4j/neoneoneo \
  -e NEO4J_DATABASE=neo4j \
  -- node "$(pwd)/build/index.js"
```

This adds the MCP server to **user scope**, making it available across all your projects.

**Verify the configuration:**
```bash
claude mcp list
```

You should see `neo4j` listed with ✓ Connected status.

**Note**: The installer script (`./install.sh`) automates this entire process.

### Optional: Custom Neo4j configuration

If your Neo4j instance uses a different URI or database, add these environment variables:

```json
{
  "mcpServers": {
    "neo4j": {
      "command": "node",
      "args": ["/absolute/path/to/mcp-neo4j-claude-code-server/build/index.js"],
      "env": {
        "NEO4J_AUTH": "neo4j/neoneoneo",
        "NEO4J_URI": "bolt://localhost:7687",
        "NEO4J_DATABASE": "neo4j"
      }
    }
  }
}
```

## Verification

1. Restart Claude Code CLI if it's currently running

2. Start a new Claude Code session

3. The Neo4j MCP tools should now be available. Test with:
   ```
   "Show me all nodes in the database"
   ```

4. Claude should respond using the Neo4j MCP server to query your database

## Environment Variables

| Variable | Required | Default | Description | Example |
|----------|----------|---------|-------------|---------|
| `NEO4J_AUTH` | **Yes** | None | Username and password separated by `/` | `neo4j/neoneoneo` |
| `NEO4J_URI` | No | `bolt://localhost:7687` | Neo4j connection URI | `bolt://neo4j.example.com:7687` |
| `NEO4J_DATABASE` | No | `neo4j` | Database name (Neo4j Enterprise) | `myDatabase` |

### NEO4J_AUTH Format

The `NEO4J_AUTH` variable must follow the format: `username/password`

- Use exactly one forward slash (`/`) as separator
- Both username and password must be non-empty
- Example: `NEO4J_AUTH=neo4j/neoneoneo`

## Troubleshooting

### Error: "NEO4J_AUTH environment variable is required"

**Cause**: The `NEO4J_AUTH` variable is not set in your MCP configuration.

**Solution**: Add `NEO4J_AUTH` when configuring the MCP server with `claude mcp add -e NEO4J_AUTH=username/password`.

### Error: "NEO4J_AUTH must contain exactly one '/' separator"

**Cause**: The `NEO4J_AUTH` format is incorrect.

**Solution**: Ensure the format is `username/password` with exactly one `/` separator.

### Error: "Connection refused" or "Unable to connect to Neo4j"

**Cause**: Neo4j server is not running or not accessible.

**Solution**:
- Verify Neo4j is running: Check `http://localhost:7474` (Neo4j Browser)
- For Docker: `docker ps | grep neo4j`
- For local install: Check Neo4j service status

### Error: "Authentication failed"

**Cause**: Incorrect username or password in `NEO4J_AUTH`.

**Solution**:
- Verify credentials match your Neo4j configuration
- Check Neo4j logs for authentication errors
- Test credentials using Neo4j Browser at `http://localhost:7474`

### Claude Code doesn't recognize Neo4j tools

**Cause**: Claude Code hasn't loaded the MCP server configuration.

**Solution**:
1. Verify the server is configured: `claude mcp get neo4j`
2. Ensure the build completed successfully: `ls build/index.js`
3. Check the server path is correct: `claude mcp get neo4j` should show the correct absolute path
4. Restart Claude Code CLI completely
5. Verify with `claude mcp list` - the neo4j server should appear with ✓ Connected status

## Testing

### Quick Test with Local Neo4j

If you have Neo4j running locally with default credentials:

```bash
# Set environment and test the server directly
NEO4J_AUTH=neo4j/neoneoneo node build/index.js
```

The server should output: `Neo4j MCP server for Claude Code running on stdio`

Press `Ctrl+C` to stop.

### Test Queries via Claude Code

Once configured, try these test queries in Claude Code:

1. **List nodes**: "Show me all nodes in the database"
2. **Create node**: "Create a Person node with name 'Alice' and age 30"
3. **Query specific data**: "Find all nodes with label Person"
4. **Create relationship**: "Create a KNOWS relationship between Alice and Bob"

### Verify in Neo4j Browser

Open `http://localhost:7474` in your web browser to visually verify the data created through Claude Code.

## Next Steps

- Read the [README.md](README.md) for usage examples
- Explore Cypher query syntax at [Neo4j Cypher Manual](https://neo4j.com/docs/cypher-manual/current/)
- Try natural language queries through Claude Code
