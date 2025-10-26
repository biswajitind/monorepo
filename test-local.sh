#!/bin/bash
# Local testing script for the monorepo nginx service

set -e

echo "🔨 Building Docker image..."
cd devtools/nginx
docker build -t monorepo-nginx:test .

echo "🚀 Starting container..."
docker run -d -p 8080:80 --name monorepo-test monorepo-nginx:test

echo "⏳ Waiting for container to be ready..."
sleep 3

echo "🧪 Testing application..."

# Test 1: Check HTTP status code
status_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$status_code" -eq 200 ]; then
    echo "✅ Test 1 passed: Server responded with HTTP 200"
else
    echo "❌ Test 1 failed: Server responded with HTTP $status_code"
    docker stop monorepo-test
    docker rm monorepo-test
    exit 1
fi

# Test 2: Check page content
if curl -s http://localhost:8080 | grep -q "Welcome to the World"; then
    echo "✅ Test 2 passed: Page contains expected content"
else
    echo "❌ Test 2 failed: Page does not contain expected content"
    docker stop monorepo-test
    docker rm monorepo-test
    exit 1
fi

# Test 3: Display container logs
echo ""
echo "📋 Container logs:"
docker logs monorepo-test

echo ""
echo "🎉 All tests passed!"

# Cleanup
echo "🧹 Cleaning up..."
docker stop monorepo-test
docker rm monorepo-test

echo "✨ Done!"
