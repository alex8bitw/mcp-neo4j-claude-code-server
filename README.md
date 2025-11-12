# MCP Neo4j Server for Claude Code

> **Note**: This version is specifically designed for Claude Code CLI. For Claude Desktop integration, please use version 0.2.0 or earlier.

An MCP server that provides integration between Neo4j graph database and Claude Code CLI, enabling graph database operations through natural language interactions.

## Quick Start

See [INSTALL.md](INSTALL.md) for detailed installation and configuration instructions.

### Basic Configuration

Add this to your Claude Code MCP settings (`mcp_settings.json`):

```json
{
  "mcpServers": {
    "neo4j": {
      "command": "node",
      "args": ["/absolute/path/to/mcp-neo4j-claude-code-server/build/index.js"],
      "env": {
        "NEO4J_AUTH": "neo4j/your-password"
      }
    }
  }
}
```

**Note**: Replace `/absolute/path/to/mcp-neo4j-claude-code-server` with the actual path to your installation.

## Features

This server provides tools for interacting with a Neo4j database:

### Neo4j Enterprise Support

This server now supports connecting to specific databases in Neo4j Enterprise Edition. By default, it connects to the "neo4j" database, but you can specify a different database using the `NEO4J_DATABASE` environment variable.

### Tools

- `execute_query`: Execute Cypher queries on the Neo4j database
  - Supports all types of Cypher queries (READ, CREATE, UPDATE, DELETE)
  - Returns query results in a structured format
  - Parameters can be passed to prevent injection attacks

- `create_node`: Create a new node in the graph database
  - Specify node labels and properties
  - Returns the created node with its internal ID
  - Supports all Neo4j data types for properties

- `create_relationship`: Create a relationship between two existing nodes
  - Define relationship type and direction
  - Add properties to relationships
  - Requires node IDs for source and target nodes

## Installation

1. Clone or navigate to the repository:
```bash
git clone https://github.com/alex8bitw/mcp-neo4j-claude-code-server.git
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

For detailed setup instructions, see [INSTALL.md](INSTALL.md).

## Configuration

The server requires the following environment variables:

- `NEO4J_AUTH`: Username and password in format `username/password` **(required)**
  - Example: `neo4j/neoneoneo`
- `NEO4J_URI`: Neo4j database URI (default: `bolt://localhost:7687`)
- `NEO4J_DATABASE`: Neo4j database name (default: `neo4j`) - Use this to connect to a specific database in Neo4j Enterprise

## Usage Examples

Here are examples of how you can interact with the Neo4j database using natural language:

### Connecting to a Specific Database

For Neo4j Enterprise users with multiple databases, you can specify which database to connect to:

```json
{
  "mcpServers": {
    "neo4j": {
      "command": "node",
      "args": ["/absolute/path/to/mcp-neo4j-claude-code-server/build/index.js"],
      "env": {
        "NEO4J_AUTH": "neo4j/your-password",
        "NEO4J_URI": "bolt://localhost:7687",
        "NEO4J_DATABASE": "myCustomDatabase"
      }
    }
  }
}
```

This will connect to "myCustomDatabase" instead of the default "neo4j" database.

### Querying Data

You can ask questions like:
- "Show me all employees in the Sales department"
- "Find the top 5 oldest customers"
- "Who has purchased more than 3 products in the last month?"

Example:
```
User: "Show me all employees in the Sales department"

Claude: Let me query the database for Sales department employees.

[Executes query internally: MATCH (e:Employee)-[:WORKS_IN]->(d:Department {name: 'Sales'}) RETURN e.name, e.position]

Result:
- John Smith (Sales Manager)
- Sarah Johnson (Sales Representative)
- Mike Brown (Account Executive)
```

### Creating Data

You can give instructions like:
- "Add a new person named John Doe who is 30 years old"
- "Create a product called 'Premium Coffee' with price $24.99"
- "Add a new department called 'Research & Development'"

Example:
```
User: "Add a new person named John Doe who is 30 years old"

Claude: I'll create a new Person node with the provided information.

[Creates node internally with label 'Person' and properties {name: 'John Doe', age: 30}]

Result: Created new person node with ID: 123
```

### Creating Relationships

You can request relationships like:
- "Make John Doe friends with Jane Smith"
- "Set Product A as a component of Product B"
- "Assign John Doe to the Sales department"

Example:
```
User: "Make John Doe friends with Jane Smith"

Claude: I'll create a friendship relationship between these two people.

[Creates relationship internally: MATCH (a:Person {name: 'John Doe'}), (b:Person {name: 'Jane Smith'})
CREATE (a)-[:FRIENDS_WITH {since: '2024-01-05'}]->(b)]

Result: Created friendship relationship between John Doe and Jane Smith
```

### Complex Operations

You can perform more complex operations with natural language:
- "Find all products purchased by customers who live in New York"
- "Show me friends of friends of John Doe"
- "Calculate the average age of employees in each department"

Example:
```
User: "Find all products purchased by customers who live in New York"

Claude: I'll query the database for this information.

[Executes query internally:
MATCH (c:Customer {city: 'New York'})-[:PURCHASED]->(p:Product)
RETURN c.name, collect(p.name) as products]

Result:
- Alice Wilson: [Premium Coffee, Tea Set, Cookies]
- Bob Miller: [Premium Coffee, Water Bottle]
```

## Testing

Run the test suite:

```bash
npm test
```

## License

MIT

