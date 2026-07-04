import { useCallback, useMemo } from 'react'
import { useDraggable, useDroppable } from '@dnd-kit/core'
import { useComponentStore } from '@/stores/component-store'
import { useCanvasStore } from '@/stores/canvas-store'
import { getComponentDefinition } from '@/core/component-registry'
import type { StyleProperties } from '@/types'

function styleValueToCSS(sv: { value: number; unit: string } | undefined): string | undefined {
  if (!sv) return undefined
  return `${sv.value}${sv.unit}`
}

function boxModelToCSS(bm: any): string {
  if (!bm) return '0'
  const top = styleValueToCSS(bm.top) ?? '0'
  const right = styleValueToCSS(bm.right) ?? '0'
  const bottom = styleValueToCSS(bm.bottom) ?? '0'
  const left = styleValueToCSS(bm.left) ?? '0'
  return `${top} ${right} ${bottom} ${left}`
}

function computeStyles(styles: StyleProperties, isContainer: boolean): React.CSSProperties {
  const css: React.CSSProperties = {}

  if (styles.position === 'absolute' || styles.x || styles.y) {
    css.position = 'absolute'
    if (styles.x) css.left = styleValueToCSS(styles.x)
    if (styles.y) css.top = styleValueToCSS(styles.y)
  }

  if (styles.width) css.width = styleValueToCSS(styles.width)
  if (styles.height) css.height = styleValueToCSS(styles.height)
  if (styles.minWidth) css.minWidth = styleValueToCSS(styles.minWidth)
  if (styles.minHeight) css.minHeight = styleValueToCSS(styles.minHeight)
  if (styles.maxWidth) css.maxWidth = styleValueToCSS(styles.maxWidth)
  if (styles.maxHeight) css.maxHeight = styleValueToCSS(styles.maxHeight)

  if (styles.display) css.display = styles.display
  if (styles.flexDirection) css.flexDirection = styles.flexDirection as any
  if (styles.flexWrap) css.flexWrap = styles.flexWrap as any
  if (styles.justifyContent) css.justifyContent = styles.justifyContent as any
  if (styles.alignItems) css.alignItems = styles.alignItems as any
  if (styles.gap) css.gap = styleValueToCSS(styles.gap)

  if (styles.backgroundColor) css.backgroundColor = styles.backgroundColor
  if (styles.color) css.color = styles.color
  if (styles.opacity !== undefined) css.opacity = styles.opacity

  if (styles.fontFamily) css.fontFamily = styles.fontFamily
  if (styles.fontSize) css.fontSize = styleValueToCSS(styles.fontSize)
  if (styles.fontWeight) css.fontWeight = styles.fontWeight
  if (styles.fontStyle) css.fontStyle = styles.fontStyle
  if (styles.textAlign) css.textAlign = styles.textAlign
  if (styles.lineHeight) {
    css.lineHeight = typeof styles.lineHeight === 'number' ? styles.lineHeight : styleValueToCSS(styles.lineHeight)
  }
  if (styles.textDecoration) css.textDecoration = styles.textDecoration

  if (styles.borderWidth) css.borderWidth = styleValueToCSS(styles.borderWidth)
  if (styles.borderColor) css.borderColor = styles.borderColor
  if (styles.borderStyle && styles.borderStyle !== 'none') css.borderStyle = styles.borderStyle
  if (styles.borderRadius) css.borderRadius = styleValueToCSS(styles.borderRadius)

  if (styles.boxShadow) css.boxShadow = styles.boxShadow
  if (styles.transform) css.transform = styles.transform
  if (styles.cursor) css.cursor = styles.cursor
  if (styles.overflow) css.overflow = styles.overflow
  if (styles.zIndex !== undefined) css.zIndex = styles.zIndex

  // Padding
  if (styles.padding) {
    css.padding = boxModelToCSS(styles.padding)
  }
  // Margin
  if (styles.margin) {
    css.margin = boxModelToCSS(styles.margin)
  }

  return css
}

interface CanvasComponentProps {
  id: string
}

export function CanvasComponent({ id }: CanvasComponentProps) {
  const component = useComponentStore((s) => s.components[id])
  const selectedIds = useComponentStore((s) => s.selectedIds)
  const setSelection = useComponentStore((s) => s.setSelection)
  const isPreviewMode = useCanvasStore((s) => s.isPreviewMode)
  const updateComponentProps = useComponentStore((s) => s.updateComponentProps)
  const updateComponentStyles = useComponentStore((s) => s.updateComponentStyles)

  if (!component) return null

  const def = getComponentDefinition(component.type)
  const isSelected = selectedIds.has(id)
  const isContainer = def?.isContainer ?? false

  // Draggable
  const { attributes, listeners, setNodeRef: setDragRef, transform, isDragging } = useDraggable({
    id: `canvas-${id}`,
    data: { source: 'canvas', componentId: id, parentId: component.parentId },
    disabled: isPreviewMode,
  })

  // Droppable (for containers)
  const { setNodeRef: setDropRef, isOver } = useDroppable({
    id: `canvas-drop-${id}`,
    data: {
      parentId: id,
      index: component.children.length,
      dropPosition: 'inside',
    },
    disabled: !isContainer || isPreviewMode,
  })

  const handleClick = useCallback(
    (e: React.MouseEvent) => {
      if (isPreviewMode) return
      e.stopPropagation()
      e.preventDefault()
      if (e.shiftKey) {
        // Toggle selection
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
    [id, isSelected, setSelection, isPreviewMode]
  )

  const styles = useMemo(() => computeStyles(component.styles, isContainer), [component.styles, isContainer])

  const combinedRef = useCallback(
    (node: HTMLDivElement | null) => {
      setDragRef(node)
      if (isContainer) setDropRef(node)
    },
    [setDragRef, setDropRef, isContainer]
  )

  return (
    <div
      ref={combinedRef}
      className={`canvas-component ${isSelected && !isPreviewMode ? 'selected' : ''} ${isDragging ? 'opacity-50' : ''}`}
      style={{
        ...styles,
        ...(transform ? {
          transform: `translate(${transform.x}px, ${transform.y}px)`,
        } : {}),
        boxSizing: 'border-box',
      }}
      onClick={handleClick}
      {...(isPreviewMode ? {} : attributes)}
      {...(isPreviewMode ? {} : listeners)}
    >
      {/* Render based on component type */}
      <ComponentContent
        component={component}
        isCanvas={true}
      />

      {/* Render children for containers */}
      {isContainer && component.children.map((childId) => (
        <CanvasComponent key={childId} id={childId} />
      ))}

      {/* Drop indicator when hovering over container */}
      {isOver && !isPreviewMode && (
        <div
          style={{
            position: 'absolute',
            inset: 4,
            border: '2px dashed #3b82f6',
            borderRadius: 4,
            pointerEvents: 'none',
            background: 'rgba(59, 130, 246, 0.05)',
          }}
        />
      )}
    </div>
  )
}

// ── Component Content Renderer ──────────────────────────

function ComponentContent({ component, isCanvas }: { component: any; isCanvas: boolean }) {
  const def = getComponentDefinition(component.type)
  if (!def) return null

  const { props } = component
  const tag = def.htmlTag

  const commonStyle: React.CSSProperties = {
    width: '100%',
    height: '100%',
    boxSizing: 'border-box',
    display: component.styles?.display || 'block',
    flexDirection: component.styles?.flexDirection || undefined,
    justifyContent: component.styles?.justifyContent || undefined,
    alignItems: component.styles?.alignItems || undefined,
    gap: component.styles?.gap ? `${component.styles.gap.value}${component.styles.gap.unit}` : undefined,
    gridTemplateColumns: props.gridTemplateColumns || undefined,
    gridTemplateRows: props.gridTemplateRows || undefined,
    cursor: component.styles?.cursor || undefined,
    overflow: component.styles?.overflow || undefined,
    fontFamily: 'inherit',
    fontSize: 'inherit',
    fontWeight: 'inherit',
    color: 'inherit',
    backgroundColor: 'transparent',
    border: 'none',
    outline: 'none',
    padding: 0,
    margin: 0,
  }

  switch (component.type) {
    case 'Button':
      return (
        <button
          style={{
            ...commonStyle,
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            pointerEvents: isCanvas ? 'none' : 'auto',
          }}
          disabled={props.disabled}
        >
          {props.text || 'Button'}
        </button>
      )

    case 'Input':
      return (
        <input
          type={props.type || 'text'}
          placeholder={props.placeholder}
          defaultValue={props.value}
          style={{
            ...commonStyle,
            pointerEvents: 'none',
          }}
          readOnly
        />
      )

    case 'TextArea':
      return (
        <textarea
          placeholder={props.placeholder}
          defaultValue={props.value}
          style={{
            ...commonStyle,
            resize: 'none',
            pointerEvents: 'none',
          }}
          readOnly
        />
      )

    case 'Checkbox':
      return (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, height: '100%' }}>
          <input
            type="checkbox"
            checked={props.checked}
            style={{ pointerEvents: 'none', width: 18, height: 18 }}
            readOnly
          />
          <span style={{ fontSize: 14, color: '#333' }}>{props.label}</span>
        </div>
      )

    case 'Select':
      return (
        <select
          style={{
            ...commonStyle,
            pointerEvents: 'none',
            appearance: 'none',
          }}
        >
          {String(props.options || '')
            .split(',')
            .map((opt: string) => (
              <option key={opt.trim()} value={opt.trim()}>
                {opt.trim()}
              </option>
            ))}
        </select>
      )

    case 'Label':
      return (
        <label
          style={{
            ...commonStyle,
            display: 'inline-block',
            whiteSpace: 'nowrap',
          }}
        >
          {props.text || 'Label'}
        </label>
      )

    case 'Text':
      return (
        <span
          style={{
            ...commonStyle,
            display: 'inline-block',
            whiteSpace: 'nowrap',
          }}
        >
          {props.text || 'Hello World'}
        </span>
      )

    case 'Heading':
      const HeadingTag = props.level || 'h2'
      return (
        <HeadingTag
          style={{
            ...commonStyle,
            display: 'block',
          }}
        >
          {props.text || 'Heading'}
        </HeadingTag>
      )

    case 'Image':
      return (
        <div
          style={{
            ...commonStyle,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: props.src ? 'transparent' : '#e5e7eb',
          }}
        >
          {props.src ? (
            <img
              src={props.src}
              alt={props.alt}
              style={{
                width: '100%',
                height: '100%',
                objectFit: props.objectFit || 'cover',
              }}
            />
          ) : (
            <span style={{ fontSize: 12, color: '#9ca3af' }}>Image</span>
          )}
        </div>
      )

    case 'Container':
    case 'FlexContainer':
    case 'GridContainer':
      // Container renders children via CanvasComponent
      return null

    default:
      return (
        <div style={commonStyle}>
          {def.displayName}
        </div>
      )
  }
}
