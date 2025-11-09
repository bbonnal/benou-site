// Search functionality
let fuse = null;
let searchData = [];
let isLoading = false;
let isReady = false;

// Load search index
async function loadSearchIndex() {
  if (isLoading || isReady) return;
  isLoading = true;

  try {
    const response = await fetch("/index.json");
    searchData = await response.json();

    const options = {
      keys: [
        { name: "title", weight: 2 },
        { name: "tags", weight: 1.5 },
        { name: "content", weight: 1 },
      ],
      threshold: 0.4,
      ignoreLocation: true,
      includeScore: true,
      includeMatches: true,
      minMatchCharLength: 2,
    };

    fuse = new Fuse(searchData, options);
    isReady = true;
    console.log("Search index loaded successfully");
  } catch (error) {
    console.error("Error loading search index:", error);
  } finally {
    isLoading = false;
  }
}

// Perform search
function search(query) {
  if (!fuse || !isReady) {
    console.log("Search not ready yet");
    return [];
  }

  if (!query || query.length < 2) {
    return [];
  }

  const results = fuse.search(query);
  return results.slice(0, 10);
}

// Display search results
function displayResults(results) {
  const resultsContainer = document.getElementById("search-results");

  if (!results || results.length === 0) {
    resultsContainer.innerHTML = "";
    return;
  }

  const html = results
    .map((result) => {
      const item = result.item;
      const snippet = getSnippet(item.content, result.matches);
      const tags = item.tags
        ? item.tags.map((tag) => `<span class="tag">#${tag}</span>`).join(" ")
        : "";

      return `
            <div class="search-result">
                <a href="${item.permalink}">
                    <h3>${highlightMatches(item.title, result.matches, "title")}</h3>
                    <div class="meta">
                        <time>${item.date}</time>
                        ${tags ? `<span class="tags">${tags}</span>` : ""}
                    </div>
                    ${snippet ? `<div class="snippet">${snippet}</div>` : ""}
                </a>
            </div>
        `;
    })
    .join("");

  resultsContainer.innerHTML = html;
}

// Get snippet from content with matches
function getSnippet(content, matches) {
  if (!matches || !content) return "";

  const contentMatch = matches.find((m) => m.key === "content");
  if (!contentMatch) return "";

  const index = contentMatch.indices[0];
  const start = Math.max(0, index[0] - 50);
  const end = Math.min(content.length, index[1] + 100);

  let snippet = content.substring(start, end);
  if (start > 0) snippet = "..." + snippet;
  if (end < content.length) snippet = snippet + "...";

  return highlightMatches(snippet, matches, "content");
}

// Highlight matching text
function highlightMatches(text, matches, key) {
  if (!matches) return text;

  const match = matches.find((m) => m.key === key);
  if (!match) return text;

  let result = text;
  const indices = match.indices.sort((a, b) => b[0] - a[0]);

  indices.forEach(([start, end]) => {
    const before = result.substring(0, start);
    const highlighted = result.substring(start, end + 1);
    const after = result.substring(end + 1);
    result = before + "<mark>" + highlighted + "</mark>" + after;
  });

  return result;
}

// Initialize
document.addEventListener("DOMContentLoaded", async () => {
  const searchInput = document.getElementById("search-input");

  if (searchInput) {
    // Show loading state
    searchInput.placeholder = "loading search index...";
    searchInput.disabled = true;

    // Load search index
    await loadSearchIndex();

    // Enable search
    searchInput.placeholder = "search docs...";
    searchInput.disabled = false;
    searchInput.focus();

    // Search on input
    searchInput.addEventListener("input", (e) => {
      const query = e.target.value;
      const results = search(query);
      displayResults(results);
    });

    // Focus search with Ctrl+K
    document.addEventListener("keydown", (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === "k") {
        e.preventDefault();
        searchInput.focus();
      }

      // Clear search with Escape
      if (e.key === "Escape") {
        searchInput.value = "";
        displayResults([]);
      }
    });
  }
});
