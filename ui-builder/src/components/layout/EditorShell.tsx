import { type ReactNode, useCallback, useRef } from 'react'
import { useUIStore } from '@/stores/ui-store'
import { useComponentStore } from '@/stores/component-store'
import { useCanvasStore } from '@/stores/canvas-store'
import {
  Undo2, Redo2, ZoomIn, ZoomOut, Maximize, Eye, EyeOff,
  Save, FolderOpen, Download, Plus,
} from 'lucide-react'

interface EditorShellProps {
  children: ReactNode
  leftPanel: ReactNode
  rightPanel: ReactNode
}

export function EditorShell({ children, leftPanel, rightPanel }: EditorShellProps) {
  const leftPanelWidth = useUIStore((s) => s.leftPanelWidth)
  const rightPanelWidth = useUIStore((s) => s.rightPanelWidth)
  const setLeftPanelWidth = useUIStore((s) => s.setLeftPanelWidth)
  const setRightPanelWidth = useUIStore((s) => s.setRightPanelWidth)
  const isDirty = useComponentStore((s) => s.isDirty)

  const resizingLeft = useRef(false)
  const resizingRight = useRef(false)

  const handleMouseMove = useCallback(
    (e: MouseEvent) => {
      if (resizingLeft.current) {
        setLeftPanelWidth(e.clientX)
      }
      if (resizingRight.current) {
        setRightPanelWidth(window.innerWidth - e.clientX)
      }
    },
    [setLeftPanelWidth, setRightPanelWidth]
  )

  const handleMouseUp = useCallback(() => {
    resizingLeft.current = false
    resizingRight.current = false
    document.removeEventListener('mousemove', handleMouseMove)
    document.removeEventListener('mouseup', handleMouseUp)
    document.body.style.cursor = ''
    document.body.style.userSelect = ''
  }, [handleMouseMove])

  const startResizeLeft = useCallback(() => {
    resizingLeft.current = true
    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)
    document.body.style.cursor = 'col-resize'
    document.body.style.userSelect = 'none'
  }, [handleMouseMove, handleMouseUp])

  const startResizeRight = useCallback(() => {
    resizingRight.current = true
    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)
    document.body.style.cursor = 'col-resize'
    document.body.style.userSelect = 'none'
  }, [handleMouseMove, handleMouseUp])

  const zoom = useCanvasStore((s) => s.zoom)
  const setZoom = useCanvasStore((s) => s.setZoom)
  const resetView = useCanvasStore((s) => s.resetView)
  const isPreviewMode = useCanvasStore((s) => s.isPreviewMode)
  const togglePreviewMode = useCanvasStore((s) => s.togglePreviewMode)

  // Undo/Redo via zundo temporal store
  const handleUndo = () => {
    ;(useComponentStore as any).temporal?.getState?.()?.undo?.()
  }
  const handleRedo = () => {
    ;(useComponentStore as any).temporal?.getState?.()?.redo?.()
  }

  const handleSave = async () => {
    const store = useComponentStore.getState()
    const data = store.getProjectData()
    let filePath = store.currentFilePath

    if (!filePath) {
      const result = await window.electronAPI?.saveAsDialog()
      if (!result?.success) return
      filePath = result.filePath
      store.setFilePath(filePath)
    }

    await window.electronAPI?.saveFile(filePath!, data)
    store.markClean()
  }

  const handleOpen = async () => {
    const result = await window.electronAPI?.openFile()
    if (result?.success && result.data) {
      useComponentStore.getState().loadProject(result.data)
      useComponentStore.getState().setFilePath(result.filePath ?? null)
    }
  }

  const handleNew = () => {
    const store = useComponentStore.getState()
    // Clear everything
    store.loadProject({
      version: '1.0.0',
      metadata: { name: 'Untitled', createdAt: '', updatedAt: '', canvasWidth: 1440, canvasHeight: 900 },
      pages: [{ id: 'page-1', name: 'Page 1', route: '/', rootIds: [] }],
      components: {},
    })
    store.setFilePath(null)
    store.markClean()
  }

  return (
    <div className="editor-shell">
      {/* Toolbar */}
      <div className="flex items-center gap-1 px-3 py-1.5 bg-gray-800 border-b border-white/10">
        <button className="toolbar-btn" onClick={handleNew} title="New Project">
          <Plus size={16} />
        </button>
        <button className="toolbar-btn" onClick={handleOpen} title="Open">
          <FolderOpen size={16} />
        </button>
        <button className="toolbar-btn" onClick={handleSave} title="Save">
          <Save size={16} />
          {isDirty && <span className="w-2 h-2 rounded-full bg-yellow-400 ml-0.5" />}
        </button>

        <div className="w-px h-5 bg-white/10 mx-1" />

        <button className="toolbar-btn" onClick={handleUndo} title="Undo (Ctrl+Z)">
          <Undo2 size={16} />
        </button>
        <button className="toolbar-btn" onClick={handleRedo} title="Redo (Ctrl+Shift+Z)">
          <Redo2 size={16} />
        </button>

        <div className="w-px h-5 bg-white/10 mx-1" />

        <button className="toolbar-btn" onClick={() => setZoom(zoom - 0.1)} title="Zoom Out">
          <ZoomOut size={16} />
        </button>
        <span className="text-xs text-gray-400 w-12 text-center tabular-nums">{Math.round(zoom * 100)}%</span>
        <button className="toolbar-btn" onClick={() => setZoom(zoom + 0.1)} title="Zoom In">
          <ZoomIn size={16} />
        </button>
        <button className="toolbar-btn" onClick={resetView} title="Reset View">
          <Maximize size={14} />
        </button>

        <div className="w-px h-5 bg-white/10 mx-1" />

        <button className="toolbar-btn" onClick={togglePreviewMode} title="Preview">
          {isPreviewMode ? <EyeOff size={16} /> : <Eye size={16} />}
        </button>

        <div className="flex-1" />

        <button className="toolbar-btn" title="Export">
          <Download size={16} />
          <span className="text-xs">Export</span>
        </button>
      </div>

      {/* Main Content */}
      <div className="flex flex-1 overflow-hidden">
        {/* Left Panel */}
        <div style={{ width: leftPanelWidth }} className="flex-shrink-0 bg-gray-800/60 border-r border-white/10 overflow-hidden">
          {leftPanel}
        </div>

        {/* Panel Resizer Left */}
        <div className="panel-resizer" onMouseDown={startResizeLeft} />

        {/* Canvas Area */}
        <div className="flex-1 overflow-hidden">
          {children}
        </div>

        {/* Panel Resizer Right */}
        <div className="panel-resizer" onMouseDown={startResizeRight} />

        {/* Right Panel */}
        <div style={{ width: rightPanelWidth }} className="flex-shrink-0 bg-gray-800/60 border-l border-white/10 overflow-hidden">
          {rightPanel}
        </div>
      </div>

      {/* Status Bar */}
      <div className="flex items-center gap-4 px-3 py-1 bg-gray-800 border-t border-white/10 text-xs text-gray-500">
        <span>
          {useComponentStore.getState().selectedIds.size > 0
            ? `${useComponentStore((s) => s.selectedIds.size)} selected`
            : 'Ready'}
        </span>
        <span>{Math.round(zoom * 100)}%</span>
        <span className="flex-1" />
        {isDirty && <span className="text-yellow-500">● Unsaved changes</span>}
      </div>
    </div>
  )
}
