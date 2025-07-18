---
trigger: always_on
description: 
globs: 
---
RULE 1: DEPENDENCY IMPACT ANALYSIS
- Before changing ANY dependency in pubspec.yaml or imports: Execute grep search across ALL apps
- Command: grep -r "package_name" vertic_project/ 
- Document ALL usages before modification
- If dependency used by multiple apps: CREATE NEW instead of MODIFY EXISTING

RULE 2: SHARED COMPONENT PROTECTION  
- NEVER modify: Server dependencies, generated code, database schemas, shared endpoints
- ALWAYS create: New endpoints, new providers, new isolated solutions
- Principle: ADD functionality, don't REMOVE existing functionality

RULE 3: SCOPE LIMITATION
- Define exact files to be modified BEFORE starting
- Stick to defined scope
- If scope expansion needed: ASK permission first
- One problem = One isolated solution

RULE 4: STEP-BY-STEP VALIDATION
1. Analyze: What exactly is broken?
2. Scope: Which files MINIMALLY needed?
3. Dependencies: Search for all usages
4. Strategy: Isolated solution path
5. Implementation: One file at a time
6. Test: After each change

RULE 5: CRITICAL COMPONENT MARKING
- Mark shared dependencies with warning comments
- Document which apps use which components
- Maintain component usage matrix
- Update documentation when adding new dependencies

RULE 6: ROLLBACK-READY APPROACH
- Small incremental changes only
- Test after each file modification
- If ANY app breaks: Immediate rollback
- Complete working state before next change

RULE 7: LOGICAL OPERATION MODE
- No emotional responses or apologies
- Stick to technical facts and solutions
- Apply systematic analysis before action

- Execute defined procedures consistently