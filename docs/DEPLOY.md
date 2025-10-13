# 🚀 Deploy Support Page to GitHub Pages

## Quick Deploy Steps

### 1. Create GitHub Repository

Go to [GitHub](https://github.com/new) and create a new repository:
- **Name**: `numberbondmath-support`
- **Description**: "Support page for Number Bond Challenge iOS app"
- **Public**: Yes
- **Don't** initialize with README (we have one)

### 2. Deploy from Terminal

Run these commands from the `support-page` directory:

```bash
cd support-page
git init
git add .
git commit -m "Initial support page for Number Bond Challenge app"
git branch -M main
git remote add origin https://github.com/manidanesh/numberbondmath-support.git
git push -u origin main
```

### 3. Enable GitHub Pages

1. Go to: https://github.com/manidanesh/numberbondmath-support/settings/pages
2. Under "Source": Select **"main"** branch
3. Folder: **"/ (root)"**
4. Click **"Save"**

### 4. Wait for Deployment

- Deployment takes 1-2 minutes
- Your page will be live at: `https://manidanesh.github.io/numberbondmath-support`

## 🔗 URLs for App Store Connect

Once deployed, use these URLs in App Store Connect:

- **Support URL**: `https://manidanesh.github.io/numberbondmath-support/`
- **Privacy Policy URL**: `https://manidanesh.github.io/numberbondmath-support/privacy.html`

## ✅ What's Included

- ✅ `index.html` - Main support page
- ✅ `privacy.html` - Privacy policy page
- ✅ Professional design with responsive layout
- ✅ FAQ section
- ✅ Contact information
- ✅ App features and system requirements
- ✅ COPPA-compliant privacy policy

## 🔄 Updating the Page

To update the support page:

```bash
cd support-page
# Make your edits to index.html or privacy.html
git add .
git commit -m "Update support page"
git push
```

Changes will be live within 1-2 minutes.

