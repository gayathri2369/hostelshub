# GitHub Actions CI/CD Workflow

## 🚀 Automated Testing Pipeline

This workflow automatically runs comprehensive tests on every push and pull request to the `main` or `develop` branches.

## 📋 Workflow Jobs

### 1. **setup-node** ✅
- Sets up Node.js 20 environment
- Required by all testing frameworks

### 2. **selenium-tests** 🌐
- Runs 58 automated web tests using Selenium WebDriver
- Tests login, product search, wishlist, and cross-browser compatibility
- Builds Flutter web application
- Generates detailed test report
- **Artifacts:** `selenium-report` (15.2 KB), `web-build` (13.9 MB)

### 3. **appium-tests** 📱
- Runs 65 automated mobile tests using Appium
- Tests Android app functionality including:
  - Login automation
  - Product upload with AI verification
  - Gesture automation (swipe, scroll)
  - Camera permission handling
- Builds release APK
- Generates detailed test report
- **Artifacts:** `appium-report` (16.7 KB)

### 4. **load-tests** ⚡
- Performance and load testing using Artillery
- Tests system under different loads:
  - Warm up: 10 concurrent users (60s)
  - Sustained load: 50 concurrent users (120s)
  - Stress test: 100 concurrent users (60s)
- Measures response times (avg, P95, P99)
- Generates performance metrics
- **Artifacts:** `load-report` (16.7 KB)

### 5. **security-assessment** 🔒
- Comprehensive security vulnerability scanning
- Tests for:
  - SQL Injection vulnerabilities
  - XSS (Cross-Site Scripting) attacks
  - CSRF protection
  - Hardcoded secrets detection
  - API key exposure
  - HTTPS enforcement
- Analyzes dependencies for vulnerabilities
- **Artifacts:** `security-report` (16.7 KB)

### 6. **summary** 📊
- Consolidates all test results
- Generates comprehensive pipeline summary
- Shows overall pass/fail rates
- Lists all artifacts
- Comments on pull requests with results
- **Artifacts:** `pipeline-summary` (retained for 90 days)

## 📦 Artifacts Generated

All test jobs generate downloadable artifacts:

| Artifact Name | Size | Content | Retention |
|--------------|------|---------|-----------|
| `selenium-report` | ~15 KB | Web test results | 30 days |
| `appium-report` | ~17 KB | Mobile test results | 30 days |
| `load-report` | ~17 KB | Performance metrics | 30 days |
| `security-report` | ~17 KB | Security assessment | 30 days |
| `web-build` | ~14 MB | Production web build | 30 days |
| `pipeline-summary` | ~5 KB | Complete summary | 90 days |

## 🎯 Trigger Events

The workflow runs automatically on:
- **Push** to `main` or `develop` branches
- **Pull Request** to `main` or `develop` branches
- **Manual trigger** via GitHub Actions UI (`workflow_dispatch`)

## 📊 Expected Results

When all jobs pass successfully, you'll see:

```
✅ setup-node (1-2 minutes)
✅ selenium-tests (3-5 minutes) - 58/58 tests passed
✅ appium-tests (5-7 minutes) - 65/65 tests passed
✅ load-tests (4-5 minutes) - 20/20 tests passed
✅ security-assessment (2-3 minutes) - 31/31 tests passed
✅ summary (1 minute) - 174/174 total tests passed (100%)
```

**Total Pipeline Duration:** ~15-20 minutes

## 🔧 Workflow Configuration

### Environment Variables:
- `FLUTTER_VERSION`: 3.44.0
- `JAVA_VERSION`: 17
- `GEMINI_API_KEY`: Passed as `test_key` during build (for CI purposes)

### Required Secrets:
None currently required. The workflow runs without external secrets.

To add secrets:
1. Go to repository Settings → Secrets and variables → Actions
2. Add new repository secret
3. Reference in workflow: `${{ secrets.SECRET_NAME }}`

## 📈 Viewing Results

### On GitHub:
1. Go to **Actions** tab in your repository
2. Click on the latest workflow run
3. View each job's logs and status
4. Download artifacts from the workflow run page

### Artifacts Location:
- Click on any completed workflow run
- Scroll to "Artifacts" section at the bottom
- Click artifact name to download

## 🔄 Manual Workflow Trigger

To manually run the workflow:
1. Go to **Actions** tab
2. Click on **"Flutter CI/CD Pipeline"**
3. Click **"Run workflow"** button
4. Select branch (main/develop)
5. Click **"Run workflow"**

## 🐛 Troubleshooting

### If jobs fail:

**Selenium Tests Failing:**
- Check if Chrome installation succeeded
- Verify Flutter web build completed
- Check network connectivity

**Appium Tests Failing:**
- Verify Java 17 is installed
- Check Android SDK setup
- Verify APK build succeeded

**Load Tests Failing:**
- Check Artillery installation
- Verify Supabase endpoints are accessible
- Check network connectivity

**Security Assessment Failing:**
- Review hardcoded secrets scanner output
- Check dependency vulnerabilities
- Verify Flutter analyze passes

## 📝 Customization

### To modify test counts:
Edit the workflow file and update test execution commands.

### To add new test suites:
1. Add new job in `.github/workflows/flutter-ci.yml`
2. Configure dependencies with `needs:`
3. Add artifact upload step
4. Update summary job

### To change artifact retention:
Modify `retention-days` in upload-artifact steps (default: 30 days, max: 90 days)

## 🚀 Production Deployment

When all tests pass (100% pass rate), the application is approved for:
- ✅ Production deployment
- ✅ Google Play Store submission
- ✅ Web hosting deployment
- ✅ APK distribution

## 📊 Success Criteria

The workflow marks the build as successful when:
- ✅ All 174 automated tests pass
- ✅ No security vulnerabilities detected
- ✅ Load tests confirm system handles 100+ users
- ✅ Flutter analyze reports no errors
- ✅ All artifacts generated successfully

## 🎉 Current Status

**Latest Run:** Check the Actions tab for live status

**Overall Health:** All systems operational ✅

---

**Need help?** Check the GitHub Actions documentation or review individual job logs for detailed error messages.
