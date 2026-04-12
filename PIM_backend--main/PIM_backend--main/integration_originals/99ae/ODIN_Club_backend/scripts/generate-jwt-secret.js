#!/usr/bin/env node

/**
 * Script to generate a secure JWT secret key
 * Usage: node scripts/generate-jwt-secret.js
 */

const crypto = require('crypto');

const secret = crypto.randomBytes(64).toString('hex');

console.log('\n🔐 Generated JWT Secret Key:\n');
console.log(secret);
console.log('\n📝 Copy this value to your .env file as JWT_SECRET\n');
console.log('Example:');
console.log(`JWT_SECRET=${secret}\n`);
