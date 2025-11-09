#!/bin/bash

# Hugo Post Creator
# Usage: ./create-post.sh "Post Title" [type]

show_help() {
    cat << EOF
Usage: $(basename "$0") "Post Title" [type]

Creates a new Hugo post with the specified title and optional type.

Arguments:
    Post Title    The title of the post (required, use quotes if it contains spaces)
    type          The type of post template (optional)
                  - default: Full template with placeholders for images, diagrams, etc.
                  - simple: Just the Hugo front matter with title and date

Examples:
    $(basename "$0") "My New Post"              # Creates a default post
    $(basename "$0") "Quick Note" simple        # Creates a simple post
    $(basename "$0") -h                         # Show this help message

Options:
    -h, --help    Show this help message

EOF
}

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Check if title is provided
if [ -z "$1" ]; then
    echo "Error: Post title is required"
    echo "Use -h or --help for usage information"
    exit 1
fi

TITLE="$1"
TYPE="${2:-default}"
DATE=$(date +%Y-%m-%d)

# Create slug from title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')

# Define the content directory (adjust if your Hugo structure is different)
CONTENT_DIR="content/docs"
FILENAME="${CONTENT_DIR}/${SLUG}.md"

# Create content directory if it doesn't exist
mkdir -p "$CONTENT_DIR"

# Check if file already exists
if [ -f "$FILENAME" ]; then
    echo "Error: Post already exists at $FILENAME"
    exit 1
fi

# Create the post based on type
if [ "$TYPE" == "simple" ]; then
    cat > "$FILENAME" << EOF
---
title: "$TITLE"
date: $DATE
tags: []
---

EOF
    echo "Simple post created: $FILENAME"
else
    cat > "$FILENAME" << 'EOF'
---
title: "TITLE_PLACEHOLDER"
date: DATE_PLACEHOLDER
tags: ["template", "example"]
---

## Image Placeholder

<img src="example.svg" alt="Example Image" width="200" class="centered-svg"/>
<img src="example.svg" alt="Example Image" width="200" style="display: block; margin: 0 auto;" />

## H2 Header Example

This is a paragraph under an H2 header.

### H3 Header Example

This is a paragraph under an H3 header.

#### H4 Header Example

This is a paragraph under an H4 header.

## Code Block Placeholder

```python
def hello_world():
    print("Hello, World!")
    return True
```

```bash
echo "This is a bash example"
ls -la
```

## Mermaid Diagram Placeholder

```mermaid
---
config:
  theme: 'dark'
  themeVariables:
    darkMode: true
    background: '#222222'     
    mainBkg: '#222222'            
    primaryColor: '#222222'       
    primaryTextColor: '#FFFFFF'  
    primaryBorderColor: '#32C5D2' 
    secondaryColor: '#7FB6ED'    
    secondaryBorderColor: '#7FB6ED'
    lineColor: '#666666'   
    textColor: '#FFFFFF'   
    noteBkgColor: '#222222'   
    noteTextColor: '#F57F6C'  
    noteBorderColor: '#666666'   
    activationBkgColor: '#F57F6C' 
    activationBorderColor: '#FCB5AA'
    signalColor: '#32C5D2'  
    fontFamily: 'JetBrains Mono'
    fontSize: '14px'
---
sequenceDiagram
    Alice ->> Bob: Hello Bob, how are you?
    Bob-->>John: How about you John?
    Bob--x Alice: I am good thanks!
    Bob-x John: I am good thanks!
    Note right of John: Bob thinks a long<br/>long time, so long<br/>that the text does<br/>not fit on a row.
    Bob-->Alice: Checking with John...
    Alice->John: Yes... John, how are you?
```

## Warning Box Placeholder

> **⚠️ Warning**
> 
> This is a warning message. Use this for important cautionary information.

## Info Box Placeholder

> **ℹ️ Info**
> 
> This is an informational message. Use this for helpful tips or additional context.

## Lists

### Unordered List
- First item
- Second item
- Third item
  - Nested item
  - Another nested item

### Ordered List
1. First step
2. Second step
3. Third step

## Inline Code

You can use `inline code` like this in your paragraphs.

## Links

[Link to example](https://example.com)

EOF

    # Replace placeholders
    sed -i "s/TITLE_PLACEHOLDER/$TITLE/g" "$FILENAME"
    sed -i "s/DATE_PLACEHOLDER/$DATE/g" "$FILENAME"
    
    echo "Default post created: $FILENAME"
fi

echo "Title: $TITLE"
echo "Date: $DATE"
echo "Type: $TYPE"
