# GitHub Copilot Instructions for chef-winrm-fs

## Repository Overview

This repository contains **chef-winrm-fs**, a Ruby gem providing file system operations over Windows Remote Management (WinRM). It allows uploading files, directories, and in-memory data to Windows endpoints via WinRM/PSRP protocol.

### Repository Structure

```
/
├── .github/                    # GitHub configuration and workflows
│   ├── workflows/              # CI/CD workflows
│   │   ├── lint.yml           # Linting with Cookstyle/RuboCop
│   │   ├── sonarqube.yml      # SonarQube code quality scan
│   │   └── unit.yml           # Unit tests on Windows (Ruby 3.1, 3.4)
│   └── dependabot.yml         # Dependency management
├── .rubocop.yml               # RuboCop linting configuration
├── .rubocop_todo.yml          # RuboCop pending fixes
├── .rspec                     # RSpec test configuration
├── bin/
│   └── rwinrmcp               # Command-line executable
├── lib/
│   ├── chef-winrm-fs.rb       # Main library entry point
│   └── chef-winrm-fs/         # Core library modules
│       ├── exceptions.rb      # Custom exceptions
│       ├── file_manager.rb    # Main file operations interface
│       ├── core/              # Core implementation
│       │   ├── file_transporter.rb  # File transfer logic
│       │   └── tmp_zip.rb     # Temporary ZIP handling
│       └── scripts/           # PowerShell scripts for Windows operations
│           ├── *.ps1.erb      # PowerShell script templates
│           └── scripts.rb     # Script management
├── spec/                      # Test suite
│   ├── integration/           # Integration tests
│   ├── unit/                  # Unit tests
│   ├── config-example.yml     # Test configuration template
│   ├── matchers.rb           # Custom RSpec matchers
│   └── spec_helper.rb        # Test configuration
├── Gemfile                    # Ruby dependencies
├── Rakefile                   # Build and test tasks
├── chef-winrm-fs.gemspec     # Gem specification
├── README.md                  # Documentation
├── LICENSE                    # Apache 2.0 License
├── VERSION                    # Version file
├── changelog.md              # Release notes
├── appveyor.yml              # Windows CI (legacy)
└── Vagrantfile               # Development VM setup
```

## Jira Integration Workflow

When a Jira ID is provided in a task request:

1. **Fetch Jira Issue Details**: Use the `atlassian-mcp-server` MCP server to retrieve the complete Jira issue information
2. **Read and Understand**: Analyze the story description, acceptance criteria, and requirements
3. **Plan Implementation**: Break down the task into implementable steps based on Jira requirements
4. **Implement**: Execute the implementation following the story requirements

### MCP Server Usage for Jira

Use the `atlassian-mcp-server` MCP server for all Jira operations:
- Fetch issue details using issue ID/key
- Read story descriptions and acceptance criteria
- Update issue status and add comments as needed
- Link related issues or create sub-tasks if required

## Testing Requirements

### Unit Test Coverage
- **Minimum Coverage**: Maintain >80% test coverage for all implementations
- **Test Framework**: Use RSpec for all testing
- **Test Types**:
  - Unit tests in `spec/unit/`
  - Integration tests in `spec/integration/`
- **Test Patterns**:
  - Test all public methods and classes
  - Test error conditions and edge cases
  - Mock external dependencies (WinRM connections)
  - Test PowerShell script generation

### Running Tests
```bash
# Unit tests only
bundle exec rake spec

# Integration tests (requires Windows VM)
bundle exec rake integration

# All tests
bundle exec rake all

# Linting
bundle exec rake style
```

## Pull Request Workflow

### Branch Creation and Management
When prompted to create a PR:

1. **Branch Naming**: Use the Jira ID as the branch name (e.g., `JIRA-123`)
2. **GitHub CLI Commands**:
   ```bash
   # Create and switch to feature branch
   git checkout -b JIRA-123
   
   # Make changes and commit with DCO
   git commit -s -m "Add feature X for JIRA-123"
   
   # Push branch
   git push origin JIRA-123
   
   # Create PR with GitHub CLI
   gh pr create --title "JIRA-123: Brief description" --body-file pr-description.html
   ```

3. **PR Description Format**: Use HTML tags for formatting:
   ```html
   <h2>Summary</h2>
   <p>Brief description of changes made</p>
   
   <h2>Changes</h2>
   <ul>
     <li>Change 1</li>
     <li>Change 2</li>
   </ul>
   
   <h2>Jira Issue</h2>
   <p>Closes: <a href="[jira-url]">JIRA-123</a></p>
   
   <h2>Testing</h2>
   <p>All unit tests pass with >80% coverage</p>
   ```

### Available GitHub Labels
Apply appropriate labels to PRs:
- `bug`: Something isn't working
- `documentation`: Improvements or additions to documentation
- `enhancement`: New feature or request
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention is needed
- `oss-standards`: Related to OSS Repository Standardization
- `question`: Further information is requested

## DCO (Developer Certificate of Origin) Compliance

**All commits MUST include DCO sign-off**:

### Requirements
- Every commit must be signed with `-s` or `--signoff` flag
- Commit message format: `git commit -s -m "Your commit message"`
- This certifies you have the right to submit the code under the project's license

### DCO Sign-off Example
```bash
git commit -s -m "Add new file upload feature

This commit implements the file upload functionality
as requested in JIRA-123.

Signed-off-by: Your Name <your.email@example.com>"
```

## Build System Integration

### GitHub Actions Workflows
The repository uses GitHub Actions for CI/CD:

1. **Unit Tests** (`unit.yml`):
   - Runs on Windows 2019/2022
   - Tests Ruby 3.1 and 3.4
   - Executes `bundle exec rake spec`

2. **Linting** (`lint.yml`):
   - Uses Cookstyle (Chef's RuboCop configuration)
   - Runs on Ubuntu latest with Ruby 3.1
   - Command: `cookstyle --chefstyle -c .rubocop.yml`

3. **SonarQube** (`sonarqube.yml`):
   - Code quality analysis
   - Runs on pull requests and main branch pushes

### No Expeditor Integration
This repository does not use Chef's Expeditor build system. All builds are handled through GitHub Actions.

## Step-by-Step Development Workflow

### Complete Implementation Workflow

1. **Initial Setup**
   - Receive task with Jira ID
   - Fetch Jira issue details using `atlassian-mcp-server`
   - Read and understand requirements
   - **Prompt**: "Jira issue fetched. Requirements understood. Ready to proceed with implementation planning?"

2. **Planning Phase**
   - Break down requirements into implementable steps
   - Identify files that need modification
   - Plan test cases and coverage strategy
   - **Prompt**: "Implementation plan created. The following files will be modified: [list]. Proceed with implementation?"

3. **Implementation Phase**
   - Create feature branch using Jira ID
   - Implement changes following Ruby and Chef coding standards
   - Ensure no prohibited files are modified
   - **Prompt**: "Core implementation complete. Ready to proceed with test creation?"

4. **Testing Phase**
   - Create comprehensive unit tests
   - Run test suite to ensure >80% coverage
   - Fix any failing tests
   - **Prompt**: "Tests created and passing with >80% coverage. Ready to proceed with linting and quality checks?"

5. **Quality Assurance**
   - Run linting with Cookstyle
   - Fix any style violations
   - Ensure all CI workflows pass
   - **Prompt**: "Code quality checks complete. Ready to create pull request?"

6. **Pull Request Creation**
   - Commit changes with DCO sign-off
   - Push feature branch
   - Create PR with proper HTML description
   - Apply appropriate labels
   - **Prompt**: "Pull request created successfully. Task implementation complete. Need any additional changes or ready to move to next task?"

### Continuation Prompts

After each major step, ask:
- **Summary**: Provide what was accomplished
- **Next Step**: Clearly state the next action
- **Remaining Steps**: List what steps are left
- **Confirmation**: "Do you want to continue with the next step?"

## Prohibited File Modifications

Do not modify these files without explicit permission:
- `.github/workflows/` (CI/CD configurations)
- `Gemfile` and `chef-winrm-fs.gemspec` (unless dependency changes are specifically requested)
- `LICENSE` and `VERSION` files
- `.rubocop.yml` and `.rubocop_todo.yml` (linting configurations)

## Code Standards

### Ruby/Chef Standards
- Follow Chef's coding standards and Cookstyle rules
- Use frozen string literals: `# frozen_string_literal: true`
- Maintain consistent indentation (2 spaces)
- Write descriptive method and variable names
- Include proper documentation and comments

### File Patterns
- Ruby files: Use `.rb` extension
- Tests: Follow `*_spec.rb` naming in appropriate spec directories
- PowerShell scripts: Use `.ps1.erb` for templates in `lib/chef-winrm-fs/scripts/`

### Git Commit Standards
- Use conventional commit format
- Include DCO sign-off on every commit
- Reference Jira IDs in commit messages
- Write descriptive commit messages

## Additional Guidelines

### Local Development
- All tasks are performed on local repository
- Use local git configuration and GitHub CLI
- Test changes locally before pushing
- Verify CI workflows pass after PR creation

### Communication Pattern
- Always provide step-by-step summaries
- Ask for confirmation before proceeding to next steps
- Clearly communicate what was accomplished and what's remaining
- Prompt user for continuation after each major milestone

## AI-Assisted Development & Compliance

- ✅ Create PR with `ai-assisted` label (if label doesn't exist, create it with description "Work completed with AI assistance following Progress AI policies" and color "9A4DFF")
- ✅ Include "This work was completed with AI assistance following Progress AI policies" in PR description

### Jira Ticket Updates (MANDATORY)

- ✅ **IMMEDIATELY after PR creation**: Update Jira ticket custom field `customfield_11170` ("Does this Work Include AI Assisted Code?") to "Yes"
- ✅ Use atlassian-mcp tools to update the Jira field programmatically
- ✅ **CRITICAL**: Use correct field format: `{"customfield_11170": {"value": "Yes"}}`
- ✅ Verify the field update was successful

### Documentation Requirements

- ✅ Reference AI assistance in commit messages where appropriate
- ✅ Document any AI-generated code patterns or approaches in PR description
- ✅ Maintain transparency about which parts were AI-assisted vs manual implementation

### Workflow Integration

This AI compliance checklist should be integrated into the main development workflow Step 4 (Pull Request Creation):

```
Step 4: Pull Request Creation & AI Compliance
- Step 4.1: Create branch and commit changes WITH SIGNED-OFF COMMITS
- Step 4.2: Push changes to remote
- Step 4.3: Create PR with ai-assisted label
- Step 4.4: IMMEDIATELY update Jira customfield_11170 to "Yes"
- Step 4.5: Verify both PR labels and Jira field are properly set
- Step 4.6: Provide complete summary including AI compliance confirmation
```

- **Never skip Jira field updates** - This is required for Progress AI governance
- **Always verify updates succeeded** - Check response from atlassian-mcp tools
- **Treat as atomic operation** - PR creation and Jira updates should happen together
- **Double-check before final summary** - Confirm all AI compliance items are completed

### Audit Trail

All AI-assisted work must be traceable through:

1. GitHub PR labels (`ai-assisted`)
2. Jira custom field (`customfield_11170` = "Yes")
3. PR descriptions mentioning AI assistance
4. Commit messages where relevant

---

This workflow ensures consistent, high-quality contributions while maintaining proper documentation and testing standards.
