export function getIndexInRing(text: string) {
    let hash = 0;

    for (const c of text) {
        hash = hash * 31 + (c.codePointAt(0) ?? 0);
    }

    return hash % 1_000_000_000_000;
}

export function getClosestEntry(map: Map<number, any>, target: number) {
    for (let i = target; i >= 0; i--) {
        if (map.has(i)) {
            return { key: i, value: map.get(i) };
        }
    }
    return null;
}