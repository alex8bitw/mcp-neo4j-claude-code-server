# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Model Context Protocol (MCP) server that integrates Neo4j graph database with Claude Code CLI. It exposes three main tools (`execute_query`, `create_node`, `create_relationship`) through the MCP SDK, enabling Claude to interact with Neo4j databases through natural language.

## Build and Development Commands

```bash
# Install dependencies
npm install

# Build TypeScript to JavaScript (output in build/)
npm run build

# Watch mode for development
npm run watch

# Test the MCP inspector
npx @modelcontextprotocol/inspector build/index.js
```

The build process compiles TypeScript and makes `build/index.js` executable.

## Architecture

### Entry Point and Server Lifecycle (`src/index.ts`)

- Parses `NEO4J_AUTH` environment variable (format: `username/password`)
- Validates auth format and creates configuration object
- Instantiates `Neo4jServer` with config
- Handles SIGINT/SIGTERM for graceful shutdown
- Exits with error codes if configuration is invalid

### MCP Server Implementation (`src/server.ts`)

The `Neo4jServer` class implements the MCP protocol:

- Uses `@modelcontextprotocol/sdk` Server with StdioServerTransport
- Registers three tools via `ListToolsRequestSchema` handler:
  - `execute_query`: Executes arbitrary Cypher queries with optional parameters
  - `create_node`: Creates nodes with specified label and properties
  - `create_relationship`: Creates relationships between nodes by ID
- Tool execution via `CallToolRequestSchema` handler with type guards for argument validation
- All tool results returned as JSON text in MCP response format
- Error handling returns `isError: true` with error message

### Neo4j Client (`src/neo4j-client.ts`)

The `Neo4jClient` class abstracts Neo4j driver operations:

- Manages Neo4j driver connection with optional database selection (Enterprise Edition)
- `executeQuery<T>()`: Generic query executor that transforms Neo4j records to plain objects
  - Converts Neo4j `Node` objects to objects with `_id`, `_labels`, and properties
  - Converts Neo4j `Relationship` objects to objects with `_id`, `_type`, and properties
  - Converts Neo4j `Integer` to JavaScript numbers
- `createNode()`: Uses parameterized CREATE query to prevent injection
- `createRelationship()`: Matches nodes by internal ID and creates typed relationships
- Session management: Opens session per query, closes in finally block

### Configuration

The MCP server is configured in user scope using `claude mcp add` command.

Environment variables:

- `NEO4J_AUTH` (required): Format `username/password`, validated on startup
- `NEO4J_URI` (optional): Defaults to `bolt://localhost:7687`
- `NEO4J_DATABASE` (optional): Defaults to `neo4j`, used for Enterprise multi-database

## Code Patterns

### Type Safety

- TypeScript with strict mode enabled
- Type guards for runtime validation of MCP tool arguments (`isExecuteQueryArgs`, etc.)
- Generic type parameter on `executeQuery<T>()` for typed query results

### Error Handling

- MCP errors use `McpError` with appropriate `ErrorCode` (InvalidParams, MethodNotFound)
- Database errors caught and returned as MCP error responses with `isError: true`
- Startup validation fails fast with descriptive error messages and exit(1)

### Neo4j Patterns

- Cypher queries use parameterized inputs (`$props`, `$fromId`, etc.) to prevent injection
- Node IDs converted with `neo4j.int()` for type compatibility
- Label and relationship type names are string-interpolated (not parameterized in Cypher)
- Sessions always closed via try/finally to prevent connection leaks

## Important Notes

- The server communicates via stdio (StdioServerTransport) for MCP protocol
- All console output uses `console.error()` to avoid interfering with stdio MCP messages
- This version (0.3.0+) is designed for Claude Code CLI, not Claude Desktop
- Version 0.2.0 and earlier targeted Claude Desktop integration
