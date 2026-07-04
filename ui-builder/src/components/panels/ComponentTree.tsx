import { useCallback } from 'react'
import { useDraggable, useDroppable } from '@dnd-kit/core'
import { useComponentStore } from '@/stores/component-store'
import { getComponentDefinition } from '@/core/component-registry'
import { ChevronRight, ChevronDown, Eye, EyeOff, Trash2 } from 'lucide-react'

function TreeNode({ id, depth = 0 }: { id: string; depth: number }) {
  const component = useComponentStore((s) => s.components[id])
  const selectedIds = useComponentStore((s) => s.selectedIds)
  const setSelection = useComponentStore((s) => s.setSelection)
  const removeComponent = useComponentStore((s) => s.removeComponent)
  const def = component ? getComponentDefinition(component.type) : null

  if (!component) return null

  const isSelected = selectedIds.has(id)
  const isContainer = def?.isContainer ?? false
  const hasChildren = component.children.length > 0

  const { attributes, listeners, setNodeRef: setDragRef, isDragging } = useDraggable({
    id: `tree-${id}`,
    data: { source: 'tree', componentId: id, parentId: component.parentId },
  })

  const { setNodeRef: setDropRef, isOver } = useDroppable({
    id: `tree-drop-${id}`,
    data: { parentId: id, index: component.children.length, dropPosition: 'inside' },
    disabled: !isContainer,
  })

  const handleClick = useCallback(
    (e: React.MouseEvent) => {
      e.stopPropagation()
      if (e.shiftKey) {
        const store = useComponentStore.getState()
        if (isSelected) {
          store.removeFromSelection(id)
        } else {
          store.addToSelection(id)
        }
      } else {
        setSelection([id])
      }
    },
    [id, isSelected, setSelection]
  )

  const handleDelete = useCallback(
    (e: React.MouseEvent) => {
      e.stopPropagation()
      removeComponent(id)
    },
    [id, removeComponent]
  )

  return (
    <div>
      <div
        ref={(node) => { setDragRef(node); if (isContainer) setDropRef(node) }}
        className={`flex items-center gap-1 py-1 px-2 cursor-pointer text-sm rounded ${isSelected ? 'bg-blue-500/20 text-blue-300' : 'text-gray-300 hover:bg-white/5'} ${isDragging ? 'opacity-40' : ''} ${isOver ? 'ring-1 ring-blue-400' : ''}`}
        style={{ paddingLeft: depth * 16 + 8 }}
        onClick={handleClick}
        {...listeners}
        {...attributes}
      >
        {isContainer && hasChildren ? (
          <ChevronDown size={12} className="text-gray-500 flex-shrink-0" />
        ) : isContainer ? (
          <ChevronRight size={12} className="text-gray-500 flex-shrink-0" />
        ) : (
          <span className="w-3 flex-shrink-0" />
        )}
        <span className="truncate flex-1 text-xs">
          {def?.displayName || component.type}
        </span>
        <span className="text-xs text-gray-500 flex-shrink-0">{component.type}</span>
        <button
          className="text-gray-600 hover:text-red-400 flex-shrink-0 ml-1"
          onClick={handleDelete}
          title="Delete"
        >
          <Trash2 size={11} />
        </button>
      </div>
      {isContainer && component.children.map((childId) => (
        <TreeNode key={childId} id={childId} depth={depth + 1} />
      ))}
    </div>
  )
}

export function ComponentTree() {
  const rootIds = useComponentStore((s) => s.rootIds)
  const components = useComponentStore((s) => s.components)

  if (rootIds.length === 0) {
    return (
      <div className="p-4 text-center text-gray-500 text-sm">
        <p>No components on the canvas.</p>
        <p className="mt-1 text-xs">Drag components from the palette.</p>
      </div>
    )
  }

  return (
    <div className="py-2 overflow-y-auto h-full">
      <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 pb-2">
        Component Tree
      </div>
      {rootIds.map((id) => (
        <TreeNode key={id} id={id} depth={0} />
      ))}
    </div>
  )
}
