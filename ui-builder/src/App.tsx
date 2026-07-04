import { useCallback, useEffect } from 'react'
import { DndContext, DragOverlay, PointerSensor, useSensor, useSensors } from '@dnd-kit/core'
import { EditorShell } from '@/components/layout/EditorShell'
import { Canvas } from '@/components/canvas/Canvas'
import { ComponentPalette } from '@/components/panels/ComponentPalette'
import { ComponentTree } from '@/components/panels/ComponentTree'
import { PropertyEditor } from '@/components/panels/PropertyEditor'
import { StyleEditor } from '@/components/panels/StyleEditor'
import { useComponentStore } from '@/stores/component-store'
import { useCanvasStore } from '@/stores/canvas-store'
import { useUIStore } from '@/stores/ui-store'
import { getComponentDefinition } from '@/core/component-registry'
import type { ComponentDefinition } from '@/types'

export default function App() {
  const addComponent = useComponentStore((s) => s.addComponent)
  const setDropTarget = useCanvasStore((s) => s.setDropTarget)
  const leftPanelTab = useUIStore((s) => s.leftPanelTab)
  const rightPanelTab = useUIStore((s) => s.rightPanelTab)

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 4 },
    })
  )

  const handleDragStart = useCallback(() => {
    // Tracked by dnd-kit
  }, [])

  const handleDragEnd = useCallback(
    (event: any) => {
      setDropTarget(null)
      const { active, over } = event

      if (!over || !active) return

      const isPaletteDrag = active.data.current?.source === 'palette'
      const isCanvasDrag = active.data.current?.source === 'canvas'
      const isTreeDrag = active.data.current?.source === 'tree'

      if (isPaletteDrag) {
        const componentType = active.data.current?.type as string
        if (!componentType) return

        const targetParentId = over.data.current?.parentId ?? null
        const targetIndex = over.data.current?.index ?? 0

        addComponent(targetParentId, targetIndex, componentType)
      }

      // Canvas and tree moves handled in their respective components
    },
    [addComponent, setDropTarget]
  )

  const handleDragOver = useCallback((event: any) => {
    const { over, active } = event
    if (!over || !active) {
      setDropTarget(null)
      return
    }

    if (active.data.current?.source === 'palette') {
      setDropTarget({
        parentId: over.data.current?.parentId ?? null,
        index: over.data.current?.index ?? 0,
        dropPosition: over.data.current?.dropPosition ?? 'inside',
      })
    }
  }, [setDropTarget])

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const store = useComponentStore.getState()
      const isCtrl = e.ctrlKey || e.metaKey

      if (e.key === 'Delete' || e.key === 'Backspace') {
        store.selectedIds.forEach((id) => store.removeComponent(id))
      }

      if (isCtrl && e.key === 'z' && !e.shiftKey) {
        e.preventDefault()
        // zundo provides undo via temporal; trigger through the store's temporal api
        ;(useComponentStore as any).temporal?.getState?.()?.undo?.()
      }

      if (isCtrl && e.key === 'z' && e.shiftKey) {
        e.preventDefault()
        ;(useComponentStore as any).temporal?.getState?.()?.redo?.()
      }

      if (isCtrl && e.key === 'a') {
        e.preventDefault()
        store.selectAll()
      }

      if (e.key === 'Escape') {
        store.clearSelection()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  const leftPanel = (
    <div className="flex flex-col h-full">
      <div className="flex border-b border-white/10">
        <button
          className={`flex-1 py-2 text-xs font-medium ${leftPanelTab === 'components' ? 'text-blue-400 border-b-2 border-blue-400' : 'text-gray-400'}`}
          onClick={() => useUIStore.getState().setLeftPanelTab('components')}
        >
          Components
        </button>
        <button
          className={`flex-1 py-2 text-xs font-medium ${leftPanelTab === 'outline' ? 'text-blue-400 border-b-2 border-blue-400' : 'text-gray-400'}`}
          onClick={() => useUIStore.getState().setLeftPanelTab('outline')}
        >
          Outline
        </button>
      </div>
      <div className="flex-1 overflow-hidden">
        {leftPanelTab === 'components' ? <ComponentPalette /> : <ComponentTree />}
      </div>
    </div>
  )

  const rightPanel = (
    <div className="flex flex-col h-full">
      <div className="flex border-b border-white/10">
        <button
          className={`flex-1 py-2 text-xs font-medium ${rightPanelTab === 'properties' ? 'text-blue-400 border-b-2 border-blue-400' : 'text-gray-400'}`}
          onClick={() => useUIStore.getState().setRightPanelTab('properties')}
        >
          Properties
        </button>
        <button
          className={`flex-1 py-2 text-xs font-medium ${rightPanelTab === 'styles' ? 'text-blue-400 border-b-2 border-blue-400' : 'text-gray-400'}`}
          onClick={() => useUIStore.getState().setRightPanelTab('styles')}
        >
          Styles
        </button>
      </div>
      <div className="flex-1 overflow-y-auto">
        {rightPanelTab === 'properties' ? <PropertyEditor /> : <StyleEditor />}
      </div>
    </div>
  )

  return (
    <DndContext
      sensors={sensors}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onDragOver={handleDragOver}
    >
      <EditorShell leftPanel={leftPanel} rightPanel={rightPanel}>
        <Canvas />
      </EditorShell>
    </DndContext>
  )
}
