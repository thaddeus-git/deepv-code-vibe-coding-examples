#!/bin/bash

# Download Whisper model script for macOS ARM
# This script downloads the optimal model based on your requirements

MODEL_DIR="Sources/Models"
mkdir -p "$MODEL_DIR"

echo "🎙️ WhisperTranscribe Model Downloader"
echo "======================================"

# Function to download model
download_model() {
    local model_name=$1
    local model_url=$2
    local file_name=$3
    
    echo "📥 Downloading $model_name model..."
    
    if [ ! -f "$MODEL_DIR/$file_name" ]; then
        curl -L "$model_url" -o "$MODEL_DIR/$file_name"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully downloaded $model_name"
            return 0
        else
            echo "❌ Failed to download $model_name"
            return 1
        fi
    else
        echo "✅ $model_name already exists"
        return 0
    fi
}

echo ""
echo "Available models (in order of recommendation for your use case):"
echo "1. Turbo (Fastest, excellent accuracy) - ~800MB"
echo "2. Base English (Good balance) - ~150MB" 
echo "3. Small English (Faster, good for testing) - ~50MB"
echo ""

# Try to download turbo model first (best for your requirements)
echo "🚀 Attempting to download Turbo model (recommended)..."
if download_model "Turbo" "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin" "ggml-large-v3-turbo.bin"; then
    echo ""
    echo "🎉 Setup complete! You now have the fastest model for near-instant transcription."
    echo "💡 This model should give you the ~0.1 second performance you experienced with WisprFlow."
    exit 0
fi

# Fallback to base.en model
echo ""
echo "📦 Downloading Base English model as fallback..."
if download_model "Base English" "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin" "ggml-base.en.bin"; then
    echo ""
    echo "✅ Setup complete with Base English model!"
    echo "💡 This model provides excellent accuracy with good speed."
    exit 0
fi

# Final fallback to small.en model
echo ""
echo "📦 Downloading Small English model as final fallback..."
if download_model "Small English" "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin" "ggml-small.en.bin"; then
    echo ""
    echo "✅ Setup complete with Small English model!"
    echo "💡 This model is fast and suitable for testing."
    exit 0
fi

echo ""
echo "❌ Failed to download any models. Please check your internet connection and try again."
echo "🔧 You can also manually download models from: https://huggingface.co/ggerganov/whisper.cpp"
exit 1