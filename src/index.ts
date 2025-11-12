#!/usr/bin/env node
import { Neo4jServer } from './server.js';

// Load configuration from environment variables
// Parse NEO4J_AUTH (format: username/password)
const neo4jAuth = process.env.NEO4J_AUTH;

if (!neo4jAuth) {
  console.error('Error: NEO4J_AUTH environment variable is required');
  console.error('Format: username/password (e.g., NEO4J_AUTH=neo4j/neoneoneo)');
  process.exit(1);
}

// Validate NEO4J_AUTH format
const authParts = neo4jAuth.split('/');
if (authParts.length !== 2) {
  console.error('Error: NEO4J_AUTH must contain exactly one "/" separator');
  console.error('Format: username/password (e.g., NEO4J_AUTH=neo4j/neoneoneo)');
  process.exit(1);
}

const [username, password] = authParts;
if (!username || !password) {
  console.error('Error: Both username and password must be non-empty');
  console.error('Format: username/password (e.g., NEO4J_AUTH=neo4j/neoneoneo)');
  process.exit(1);
}

const config = {
  uri: process.env.NEO4J_URI || 'bolt://localhost:7687',
  username,
  password,
  database: process.env.NEO4J_DATABASE || 'neo4j',
};

// Start the server
const server = new Neo4jServer(config);

server.run().catch((error) => {
  console.error('Failed to start Neo4j MCP server:', error);
  process.exit(1);
});

// Cleanup on termination
process.on('SIGINT', async () => {
  try {
    await server.close();
    process.exit(0);
  } catch (error) {
    console.error('Error during shutdown:', error);
    process.exit(1);
  }
});

process.on('SIGTERM', async () => {
  try {
    await server.close();
    process.exit(0);
  } catch (error) {
    console.error('Error during shutdown:', error);
    process.exit(1);
  }
});
