# SuperClaude Entry Point

@COMMANDS.md
@FLAGS.md
@PRINCIPLES.md
@RULES.md
@MCP.md
@PERSONAS.md
@ORCHESTRATOR.md
@MODES.md

# Comment Style Guidelines

## Comment Preferences
- Use single-line comments `// 주석 내용..` instead of JSDoc-style comments
- Avoid multi-line JSDoc comments like `/**` and `*/` unless documenting public APIs
- Keep comments concise and inline when possible
- Use Korean for internal comments in Korean-language projects

# File Encoding Rules

## UTF-8 Encoding Standards
- **ALWAYS** ensure all files are saved with UTF-8 encoding
- **MANDATORY** cross-check for UTF-8 encoding issues before completing any file operations
- Use proper Unicode characters for Korean text (avoid escaped Unicode sequences)
- Verify Korean characters display correctly in comments and strings
- Test file encoding after any modifications containing non-ASCII characters
- When encountering encoding issues, immediately fix by re-saving with proper UTF-8 encoding