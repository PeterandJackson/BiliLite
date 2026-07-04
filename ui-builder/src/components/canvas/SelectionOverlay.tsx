import { useComponentStore } from '@/stores/component-store'

export function SelectionOverlay() {
  const selectedIds = useComponentStore((s) => s.selectedIds)
  if (selectedIds.size === 0) return null

  // In the full implementation, we'd calculate positions from the
  // component store and render resize handles at those positions.
  // For now, the selected styling is handled by CSS on each CanvasComponent.
  return null
}
