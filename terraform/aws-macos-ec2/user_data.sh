#!/bin/bash

set -e

echo "Starting macOS EC2 instance setup..."

# Update system
sudo softwareupdate --install --all --agree-to-license

# Install Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install command line tools
echo "Installing Command Line Tools..."
xcode-select --install 2>/dev/null || true

# Wait for Command Line Tools installation
while ! xcode-select -p &> /dev/null; do
    echo "Waiting for Command Line Tools..."
    sleep 5
done

# Install Xcode
echo "Installing Xcode..."
# Note: This requires App Store credentials or manual installation
# For automated setup, you may need to use xcodesorg/xcodes or similar tools

# Install Rust
if ! command -v rustc &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Install Rust iOS targets
echo "Installing Rust iOS targets..."
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios
rustup target add aarch64-apple-ios-sim

# Install cargo-lipo
echo "Installing cargo-lipo..."
cargo install cargo-lipo

# Install other development tools
echo "Installing development tools..."
brew install git gh cocoapods fastlane

# Configure git
git config --global user.email "ci@cyrillicime.com"
git config --global user.name "CI Bot"

# Install GitHub CLI and authenticate (requires token)
if [ -n "${github_runner_token}" ] && [ -n "${github_repo_url}" ]; then
    echo "Setting up GitHub Actions self-hosted runner..."

    # Create runner directory
    mkdir -p ~/actions-runner && cd ~/actions-runner

    # Download the latest runner package
    RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
    curl -o actions-runner-osx-arm64-$RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-osx-arm64-$RUNNER_VERSION.tar.gz

    # Extract the installer
    tar xzf ./actions-runner-osx-arm64-$RUNNER_VERSION.tar.gz

    # Configure the runner
    ./config.sh --url ${github_repo_url} --token ${github_runner_token} --name macos-ec2-runner --work _work --labels macos,ios,xcode --unattended

    # Install and start the service
    ./svc.sh install
    ./svc.sh start

    echo "GitHub Actions runner configured and started"
fi

# Clone the repository
echo "Cloning repository..."
cd ~
if [ -d "cyrillicJapaneseInput" ]; then
    rm -rf cyrillicJapaneseInput
fi
git clone ${github_repo_url} cyrillicJapaneseInput

# Build Rust Core for iOS
echo "Building Rust Core for iOS..."
cd ~/cyrillicJapaneseInput/rust_core
./build_ios.sh --release

# Setup Xcode project directory
echo "Setting up iOS project..."
cd ~/cyrillicJapaneseInput/mobile/iOS

# Create .gitignore for build artifacts
cat > .gitignore << 'EOF'
# Xcode
*.xcodeproj/*
!*.xcodeproj/project.pbxproj
!*.xcodeproj/xcshareddata/
!*.xcodeproj/project.xcworkspace/
*.xcworkspace/*
!*.xcworkspace/contents.xcworkspacedata
!*.xcworkspace/xcshareddata/

# Build artifacts
build/
DerivedData/
*.ipa
*.dSYM.zip
*.dSYM

# CocoaPods
Pods/
*.xcworkspace

# Carthage
Carthage/Build/

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output
EOF

echo "Setup complete!"
echo "To build iOS app, run:"
echo "  cd ~/cyrillicJapaneseInput/mobile/iOS"
echo "  xcodebuild -scheme CyrillicIME -configuration Release"
