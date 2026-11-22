export function getIndexInRing(text: string) {
    let hash = 0;

    for (const c of text) {
        hash = hash * 31 + (c.codePointAt(0) ?? 0);
    }

    return hash % 1_000_000_000_000;
}

export function getClosestEntry<V>(map: Map<number | bigint, V>, target: number | bigint) {
    const targetBig = BigInt(target);
    let bestKey: number | bigint | null = null;
    let bestValue: V | undefined;

    for (const [key, value] of map.entries()) {
        const keyBig = BigInt(key);
        if (keyBig <= targetBig && (bestKey === null || keyBig > BigInt(bestKey))) {
            bestKey = key;
            bestValue = value;
        }
    }

    return bestKey !== null ? { key: bestKey, value: bestValue } : null;
}