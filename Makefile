.PHONY: help setup upgrade format generate open

# デフォルトターゲット - ヘルプの表示
help:
	@echo "利用可能なコマンド:"
	@echo "  make setup    - 開発環境をセットアップします（SwiftFormat & Tuist）"
	@echo "  make upgrade  - 開発環境ツールをアップグレードします（SwiftFormat & Tuist）"
	@echo "  make format   - SwiftFormatでコードをフォーマットします"
	@echo "  make generate - TuistでDaroku.xcodeprojを生成します"
	@echo "  make open     - Daroku.xcodeprojをXcodeで開きます"
	@echo "  make help     - このヘルプを表示します"

# 開発環境のセットアップ（SwiftFormat & Tuist）
setup:
	@echo "開発環境をセットアップしています..."
	@if [ -d "Daroku.xcodeproj" ]; then \
		echo "Daroku.xcodeprojを削除しています..."; \
		rm -rf Daroku.xcodeproj; \
	fi
	@which brew > /dev/null || (echo "Homebrewがインストールされていません。まずHomebrewをインストールしてください。" && exit 1)
	@echo "必要なツールをインストールしています..."
	@if ! which swiftformat > /dev/null; then \
		echo "SwiftFormatをインストール中..."; \
		brew install swiftformat; \
	else \
		echo "SwiftFormatは既にインストール済み"; \
		swiftformat --version; \
	fi
	@if ! which tuist > /dev/null; then \
		echo "Tuistをインストール中..."; \
		brew install tuist; \
	else \
		echo "Tuistは既にインストール済み"; \
		tuist version; \
	fi
	@echo "プロジェクトファイルを生成しています..."
	@$(MAKE) generate
	@echo "セットアップが完了しました！"

# 開発環境ツールのバージョンアップ
upgrade:
	@echo "開発環境ツールのバージョンをアップグレードしています..."
	@which brew > /dev/null || (echo "Homebrewがインストールされていません。まずHomebrewをインストールしてください。" && exit 1)
	@if which swiftformat > /dev/null; then \
		echo "SwiftFormatをアップグレード中..."; \
		brew upgrade swiftformat || true; \
	else \
		echo "SwiftFormatがインストールされていません。'make setup'を実行してください"; \
	fi
	@if which tuist > /dev/null; then \
		echo "Tuistをアップグレード中..."; \
		tuist update || true; \
	else \
		echo "Tuistがインストールされていません。'make setup'を実行してください"; \
	fi
	@echo "開発環境ツールのアップグレードが完了しました！"

# SwiftFormatの実行
format:
	@echo "SwiftFormatでコードをフォーマットしています..."
	@if ! which swiftformat > /dev/null; then \
		echo "SwiftFormatがインストールされていません。'make setup'を実行してください"; \
		exit 1; \
	fi
	swiftformat Daroku/ DarokuTests/ DarokuUITests/

# Tuistでプロジェクトファイルを生成
generate:
	@echo "TuistでDaroku.xcodeprojを生成しています..."
	@if ! which tuist > /dev/null; then \
		echo "Tuistがインストールされていません。'make setup'を実行してください"; \
		exit 1; \
	fi
	@if [ ! -f Project.swift ]; then \
		echo "Project.swiftファイルが見つかりません"; \
		exit 1; \
	fi
	tuist generate --no-open
	@if [ -d "Daroku.xcworkspace" ]; then \
		echo "Daroku.xcworkspaceを削除しています..."; \
		rm -rf Daroku.xcworkspace; \
	fi
	@echo "Daroku.xcodeprojの生成が完了しました"

# XcodeでプロジェクトファイルをOpen
open:
	@echo "Daroku.xcodeprojをXcodeで開いています..."
	@if [ ! -d "Daroku.xcodeproj" ]; then \
		echo "Daroku.xcodeprojファイルが見つかりません。'make generate'を実行してプロジェクトファイルを生成してください"; \
		exit 1; \
	fi
	open Daroku.xcodeproj

