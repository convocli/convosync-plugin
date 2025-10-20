#!/usr/bin/env python3
"""
ConvoSync Conversation Merger
Merges two Claude Code conversation .jsonl files intelligently
"""

import json
import sys
from pathlib import Path

def load_conversation(filepath):
    """Load and parse a conversation file"""
    messages = []
    with open(filepath) as f:
        for line in f:
            if line.strip():
                messages.append(json.loads(line))
    return messages

def merge_conversations(old_messages, new_messages, target_session_id=None):
    """
    Merge old conversation into new conversation.

    Strategy:
    1. Keep old messages first (chronological order)
    2. Update all messages to use target_session_id
    3. Link old conversation's last message to new conversation's first message

    Args:
        old_messages: Messages from device A (older conversation)
        new_messages: Messages from device B (current conversation)
        target_session_id: Session ID to use (defaults to new conversation's ID)

    Returns:
        List of merged messages
    """
    if not old_messages:
        return new_messages
    if not new_messages:
        return old_messages

    # Use new conversation's session ID as target
    if target_session_id is None:
        target_session_id = new_messages[0]['sessionId']

    print(f"Merging conversations:")
    print(f"  Old: {len(old_messages)} messages")
    print(f"  New: {len(new_messages)} messages")
    print(f"  Target session ID: {target_session_id}")

    merged = []

    # Step 1: Add old messages, update session ID
    for msg in old_messages:
        msg_copy = msg.copy()
        msg_copy['sessionId'] = target_session_id
        merged.append(msg_copy)

    # Step 2: Link new conversation to old conversation
    # Update first message of new conversation to point to last of old
    old_last_uuid = old_messages[-1]['uuid']

    for msg in new_messages:
        msg_copy = msg.copy()
        msg_copy['sessionId'] = target_session_id

        # If this is the first message of new conversation (parentUuid == null)
        # Link it to the last message of old conversation
        if msg == new_messages[0] and msg_copy.get('parentUuid') is None:
            msg_copy['parentUuid'] = old_last_uuid
            print(f"  Linked new conversation start to old conversation end")

        merged.append(msg_copy)

    print(f"  Result: {len(merged)} total messages")
    return merged

def save_conversation(messages, filepath):
    """Save conversation to .jsonl file"""
    with open(filepath, 'w') as f:
        for msg in messages:
            f.write(json.dumps(msg) + '\n')
    print(f"Saved to: {filepath}")

def main():
    if len(sys.argv) < 3:
        print("Usage: merge-conversations.py <old_conversation.jsonl> <new_conversation.jsonl> [output.jsonl]")
        print()
        print("Merges old conversation (from device A) into new conversation (from device B)")
        print("Output defaults to new_conversation.jsonl (overwrites)")
        sys.exit(1)

    old_file = sys.argv[1]
    new_file = sys.argv[2]
    output_file = sys.argv[3] if len(sys.argv) > 3 else new_file

    print(f"Loading old conversation: {old_file}")
    old_messages = load_conversation(old_file)

    print(f"Loading new conversation: {new_file}")
    new_messages = load_conversation(new_file)

    print()
    merged = merge_conversations(old_messages, new_messages)

    print()
    save_conversation(merged, output_file)

    print()
    print("✓ Merge complete!")
    print(f"  {len(old_messages)} old + {len(new_messages)} new = {len(merged)} total")
    print()
    print("To use in Claude Code:")
    print(f"  The merged conversation is at: {output_file}")
    print(f"  Claude Code should automatically detect it")

if __name__ == '__main__':
    main()
