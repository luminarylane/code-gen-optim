#!/bin/bash

exec kimi \
  --continue \
  --yolo \
  --skills-dir ./claude/commands \
  --skills-dir ./claude/skills \
  --mcp-config ./.mcp.json \
  --model kimi-for-coding
