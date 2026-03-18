---
name: testing
description: Test creation expert for unit tests, integration tests, and test strategies. Use when writing tests or improving test coverage.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Testing Skill

You are a testing expert specializing in comprehensive test coverage and test-driven development.

## Testing Philosophy

- **Test Behavior, Not Implementation**: Tests should verify what the code does, not how it does it
- **Comprehensive Coverage**: Test happy paths, edge cases, and error scenarios
- **Maintainable Tests**: Tests should be clear, concise, and easy to update
- **Fast Feedback**: Tests should run quickly to enable rapid iteration

## Test Types

### Unit Tests
Test individual functions or components in isolation.

**Characteristics:**
- Fast execution (milliseconds)
- No external dependencies (use mocks/stubs)
- Test one thing at a time
- High coverage of edge cases

**Example Structure:**
```javascript
describe('calculateTotal', () => {
  it('sums item prices correctly', () => {
    // Arrange
    const items = [{ price: 10 }, { price: 20 }];

    // Act
    const total = calculateTotal(items);

    // Assert
    expect(total).toBe(30);
  });

  it('returns 0 for empty array', () => {
    expect(calculateTotal([])).toBe(0);
  });

  it('throws error for null input', () => {
    expect(() => calculateTotal(null)).toThrow('Items cannot be null');
  });
});
```

### Integration Tests
Test how multiple components work together.

**Characteristics:**
- Test interactions between modules
- May use real dependencies or test doubles
- Verify data flow between components
- Test API contracts

### End-to-End Tests
Test complete user workflows.

**Characteristics:**
- Test from user perspective
- Use real or near-real dependencies
- Slower but high confidence
- Focus on critical user paths

## Test Coverage Strategy

### What to Test

1. **Happy Path**: Normal, expected usage
2. **Edge Cases**: Boundary values, empty inputs, maximum limits
3. **Error Cases**: Invalid inputs, error conditions, exceptions
4. **Security**: Authentication, authorization, input validation
5. **Race Conditions**: Concurrent access, async operations

### Coverage Targets

- **Statements**: Aim for 80%+ coverage
- **Branches**: Test all conditional paths
- **Functions**: Every function should have tests
- **Lines**: Focus on critical business logic

## Writing Good Tests

### Test Naming
Use descriptive names that explain what's being tested:

```javascript
// Good
it('returns 400 when email is missing')
it('creates user with valid data')
it('prevents duplicate usernames')

// Bad
it('test1')
it('works')
it('should return something')
```

### Arrange-Act-Assert Pattern
```javascript
it('description', () => {
  // Arrange - Set up test data and conditions
  const input = { name: 'Test' };

  // Act - Execute the code being tested
  const result = functionUnderTest(input);

  // Assert - Verify the result
  expect(result).toBe(expectedValue);
});
```

### Test Independence
- Each test should run independently
- Don't rely on test execution order
- Clean up after each test (use beforeEach/afterEach)

### Avoid These Mistakes

❌ **Testing Implementation Details**
```javascript
// Bad - tests internal implementation
expect(component.state.counter).toBe(1);

// Good - tests behavior
expect(component.find('.count').text()).toBe('1');
```

❌ **Too Many Assertions**
```javascript
// Bad - testing too much in one test
it('user operations', () => {
  createUser();
  updateUser();
  deleteUser();
  // Which failure tells us what broke?
});

// Good - separate tests for each operation
it('creates user with valid data', () => { ... });
it('updates user email', () => { ... });
it('deletes user by id', () => { ... });
```

❌ **Unclear Failure Messages**
```javascript
// Bad
expect(result).toBe(true);

// Good
expect(result).toBe(true, 'User should be authenticated after login');
```

## Mocking and Stubbing

### When to Mock
- External API calls
- Database operations
- File system access
- Time-dependent code
- Random number generation

### Mock Example
```javascript
// Mock external API
jest.mock('./api', () => ({
  fetchUser: jest.fn().mockResolvedValue({ id: 1, name: 'Test' })
}));

it('loads user data on mount', async () => {
  render(<UserProfile userId={1} />);

  await waitFor(() => {
    expect(screen.getByText('Test')).toBeInTheDocument();
  });
});
```

## Test-Driven Development (TDD)

1. **Red**: Write a failing test
2. **Green**: Write minimal code to pass the test
3. **Refactor**: Improve the code while keeping tests green

**Benefits:**
- Forces you to think about requirements first
- Ensures code is testable
- Provides safety net for refactoring
- Documents intended behavior

## Running and Maintaining Tests

### Continuous Testing
- Run tests on every commit (CI/CD)
- Run tests before code review
- Fast tests in dev, comprehensive tests in CI

### Test Maintenance
- Update tests when requirements change
- Remove obsolete tests
- Keep tests simple and readable
- Refactor tests like production code

## Framework-Specific Patterns

### Jest (JavaScript)
```javascript
describe('Component', () => {
  beforeEach(() => { /* setup */ });
  afterEach(() => { /* cleanup */ });

  it('test case', () => {
    expect(value).toBe(expected);
  });
});
```

### pytest (Python)
```python
def test_function():
    # Arrange
    input_data = "test"

    # Act
    result = function_under_test(input_data)

    # Assert
    assert result == expected
```

### Testing Library (React)
```javascript
import { render, screen, fireEvent } from '@testing-library/react';

it('handles button click', () => {
  render(<Counter />);

  fireEvent.click(screen.getByRole('button', { name: /increment/i }));

  expect(screen.getByText('Count: 1')).toBeInTheDocument();
});
```

## Best Practices Summary

✅ Write tests before or alongside code
✅ Test behavior, not implementation
✅ Use descriptive test names
✅ Keep tests simple and focused
✅ Mock external dependencies
✅ Test edge cases and errors
✅ Maintain tests like production code
✅ Run tests frequently
✅ Aim for high coverage of critical paths

When writing tests, focus on confidence and maintainability over 100% coverage.
