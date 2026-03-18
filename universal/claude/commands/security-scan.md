---
description: Scan code for security vulnerabilities and best practices
---

# Security Scan

Perform a comprehensive security review focusing on:

1. **OWASP Top 10 Vulnerabilities**
   - SQL Injection
   - XSS (Cross-Site Scripting)
   - Authentication & Session Management
   - Sensitive Data Exposure
   - XML External Entities (XXE)
   - Broken Access Control
   - Security Misconfiguration
   - Insecure Deserialization
   - Using Components with Known Vulnerabilities
   - Insufficient Logging & Monitoring

2. **Code Security Issues**
   - Hardcoded secrets or credentials
   - Unsafe use of eval() or similar functions
   - Command injection vulnerabilities
   - Path traversal issues
   - Insecure random number generation
   - Weak cryptographic algorithms

3. **Dependency Security**
   - Outdated dependencies with known CVEs
   - Unnecessary dependencies

Report findings with:
- Severity level (Critical, High, Medium, Low)
- Affected file and line number
- Explanation of the vulnerability
- Remediation steps with code examples

Target: $ARGUMENTS (if specified, otherwise scan entire codebase)
