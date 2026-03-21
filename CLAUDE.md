# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains companion code for the Japanese book **「現場で活用するためのAIエージェント実践入門」（講談社）**. Each chapter is an independent Python project using `uv` for package management. There is no Go code despite the GOPATH location.

## Project Structure

```
chapter3/   - Basic AI agent examples (Jupyter notebooks + PostgreSQL)
chapter4/   - RAG agent (Elasticsearch + Qdrant vector search)
chapter5/   - Data analysis agent (code generation + E2B sandbox execution)
chapter6/   - Multi-agent arXiv researcher (LangGraph multi-graph)
chapter7/   - Multi-agent decision support + personalization (MACRS)
```

Each chapter directory is independent — its own `pyproject.toml`, `uv.lock`, and `.venv`. Work within the specific chapter directory.

## Common Commands (run inside each chapter directory)

```bash
uv sync                        # Install dependencies
source .venv/bin/activate      # Activate venv
uv run python <script.py>      # Run a script
uv run ruff check .            # Lint
uv run ruff format .           # Format
uv run jupyter lab             # Launch Jupyter (if applicable)
```

## Chapter-Specific Commands

### Chapter 4 (RAG Agent)
```bash
make start.engine    # Start Elasticsearch + Qdrant via Docker
make create.index    # Build search indexes
make stop.engine     # Stop Docker services
make delete.index    # Remove search indexes
```

### Chapter 6 (arXiv Researcher)
Uses LangGraph CLI with three graphs defined in `langgraph.json`:
- `research_agent`, `paper_search_agent`, `paper_analyzer_agent`

## Architecture Patterns

**Frameworks**: LangChain + LangGraph throughout. Chapter 6 also uses Anthropic and Cohere models.

**Chapter 4 structure** (`src/`): `agent.py`, `configs.py`, `models.py`, `prompts.py`, `tools/`, `scripts/`

**Chapter 5 structure** (`src/`):
- `graph/` — LangGraph graph definitions (`data_analysis.py`, `programmer.py`)
- `graph/nodes/` — Individual graph nodes (plan generation, code generation/execution, review, report)
- `graph/models/` — LangGraph state models
- `llms/`, `models/`, `modules/` — LLM wrappers, domain models, shared utilities
- `scripts/01_*.py` … `11_*.py` — Numbered scripts for step-by-step execution

**Chapter 6 structure** (`arxiv_researcher/`):
- `agent/` — Three agents: `research_agent.py`, `paper_search_agent.py`, `paper_analyzer_agent.py`
- `chains/` — LangChain chains (goal optimizer, hearing, paper processor, query decomposer, etc.)
- `models/`, `searcher/`, `service/` — Domain models, arXiv search, PDF/markdown processing

**Chapter 7 structure** (`src/`): Two agent packages — `decision_support_agent/` and `macrs/`, each with `agent.py`, `configs.py`, `models.py`, `prompts.py`

## Environment Variables

Each chapter requires a `.env` file (copy from `.env.example` or `.env.sample`). Required API keys vary:
- **All chapters**: OpenAI
- **Chapter 5**: OpenAI + E2B
- **Chapter 6**: OpenAI + Anthropic + Cohere + Jina Reader (+ LangSmith optional)

## Linting Configuration

Ruff is configured per chapter:
- **Line length**: 119 (chapters 3, 4, 6, 7) or 88 (chapter 5)
- Chapter 5 uses strict `select = ["ALL"]` with explicit ignores, and also runs `mypy`/`pyright`

## No Tests

There are no test files in this repository. All verification is done via Jupyter notebooks or numbered scripts.
