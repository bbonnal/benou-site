// Search functionality
let fuse = null;
let searchData = [];
let isLoading = false;
let isReady = false;
let currentResults = [];
let selectedIndex = -1;

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
  } catch (error) {
    console.error("Error loading search index:", error);
  } finally {
    isLoading = false;
  }
}

// Perform search
function search(query) {
  if (!fuse || !isReady) return [];
  if (!query || query.length < 2) return [];
  return fuse.search(query).slice(0, 10);
}

// Display search results
function displayResults(results) {
  const resultsContainer = document.getElementById("search-results");
  currentResults = results;
  selectedIndex = -1;

  if (!results || results.length === 0) {
    resultsContainer.innerHTML = "";
    return;
  }

  const html = results
    .map((result, i) => {
      const item = result.item;
      const snippet = getSnippet(item.content, result.matches);
      const tags = item.tags
        ? item.tags.map((tag) => `<span class="tag">#${tag}</span>`).join(" ")
        : "";

      return `
        <div class="search-result" data-index="${i}" data-href="${item.permalink}">
          <a href="${item.permalink}" tabindex="-1">
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

  // Click handler on result items
  resultsContainer.querySelectorAll(".search-result").forEach((el) => {
    el.addEventListener("mousedown", (e) => {
      e.preventDefault();
      window.location.href = el.dataset.href;
    });
    el.addEventListener("mouseenter", () => {
      setSelected(parseInt(el.dataset.index));
    });
  });
}

function setSelected(index) {
  const resultsContainer = document.getElementById("search-results");
  const items = resultsContainer.querySelectorAll(".search-result");
  if (items.length === 0) return;

  selectedIndex = Math.max(-1, Math.min(index, items.length - 1));

  items.forEach((el, i) => {
    el.classList.toggle("selected", i === selectedIndex);
  });

  if (selectedIndex >= 0) {
    items[selectedIndex].scrollIntoView({ block: "nearest" });
  }
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
    searchInput.placeholder = "loading search index...";
    searchInput.disabled = true;

    await loadSearchIndex();

    searchInput.placeholder = "search docs...";
    searchInput.disabled = false;
    searchInput.focus();

    searchInput.addEventListener("input", (e) => {
      const results = search(e.target.value);
      displayResults(results);
    });

    searchInput.addEventListener("keydown", (e) => {
      if (e.key === "ArrowDown" || e.key === "ArrowUp") {
        e.preventDefault();
        const pos = searchInput.selectionStart;
        if (e.key === "ArrowDown") setSelected(selectedIndex + 1);
        else setSelected(selectedIndex - 1);
        // Some browsers still move the cursor despite preventDefault — force it back
        requestAnimationFrame(() => searchInput.setSelectionRange(pos, pos));
      } else if (e.key === "Enter") {
        if (currentResults.length > 0) {
          const target = selectedIndex >= 0 ? selectedIndex : 0;
          window.location.href = currentResults[target].item.permalink;
        }
      } else if (e.key === "Escape") {
        searchInput.value = "";
        displayResults([]);
      }
    });

    // Ctrl+K / Cmd+K to focus search
    document.addEventListener("keydown", (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === "k") {
        e.preventDefault();
        searchInput.focus();
        searchInput.select();
      }
    });
  }
});
