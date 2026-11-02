import requests
from typing import Optional

def verify_cherokee_lexicon(query: str, dialect_filter: Optional[str] = None) -> str:
    """
    Queries the local Cherokee linguistics RAG engine to verify vocabulary spellings, 
    verb paradigms, and tonal rules across Western (Otali) and Eastern (Giduwah) sources.
    
    Args:
        query: The Cherokee word, verb root, or grammatical concept to look up.
        dialect_filter: Optional strict filter ('Western (Otali) - Durbin Feeling Lexicon', 'Eastern (Giduwah) - King / Raven Rock Dissertation', etc.). Leave blank to see all dialect variants side-by-side.
    """
    url = "http://127.0.0.1:8484/query"
    payload = {"query": query}
    if dialect_filter:
        payload["dialect_filter"] = dialect_filter
        
    try:
        response = requests.post(url, json=payload, timeout=30)
        data = response.json()
        
        output = f"### Verification Result\n{data.get('answer')}\n\n### Source Citations\n"
        for c in data.get('citations', []):
            output += f"- **File:** `{c['source']}` | **Dialect:** {c['dialect']} | **Page:** {c['page']}\n"
        return output
    except Exception as e:
        return f"[!] Error communicating with local Cherokee RAG server at port 8484: {e}"