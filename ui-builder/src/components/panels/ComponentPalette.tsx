import { useDraggable } from '@dnd-kit/core'
import { getComponentsByCategory } from '@/core/component-registry'
import type { ComponentDefinition } from '@/types'
import { Box, Columns, Grid3x3, RectangleEllipsis, Type, AlignLeft, CheckSquare, ChevronDown, Text, Heading, Image } from 'lucide-react'
import { type ReactNode } from 'react'

const iconMap: Record<string, ReactNode> = {
  'box': <Box size={16} />,
  'columns': <Columns size={16} />,
  'grid3x3': <Grid3x3 size={16} />,
  'rectangle-ellipsis': <RectangleEllipsis size={16} />,
  'type': <Type size={16} />,
  'align-left': <AlignLeft size={16} />,
  'check-square': <CheckSquare size={16} />,
  'chevron-down': <ChevronDown size={16} />,
  'text': <Text size={16} />,
  'heading': <Heading size={16} />,
  'image': <Image size={16} />,
}

const categoryLabels: Record<string, string> = {
  layout: 'Layout',
  forms: 'Forms',
  content: 'Content',
  media: 'Media',
}

function PaletteItem({ def }: { def: ComponentDefinition }) {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: `palette-${def.type}`,
    data: { source: 'palette', type: def.type },
  })

  return (
    <div
      ref={setNodeRef}
      className={`palette-item flex items-center gap-2 px-3 py-2 rounded-md text-sm text-gray-300 ${isDragging ? 'dragging' : ''}`}
      {...listeners}
      {...attributes}
    >
      <span className="text-gray-400 flex-shrink-0">{iconMap[def.icon] || <Box size={16} />}</span>
      <span className="truncate">{def.displayName}</span>
    </div>
  )
}

export function ComponentPalette() {
  const grouped = getComponentsByCategory()

  return (
    <div className="p-2 overflow-y-auto h-full">
      {Object.entries(categoryLabels).map(([catKey, catLabel]) => {
        const defs = grouped[catKey]
        if (!defs || defs.length === 0) return null

        return (
          <div key={catKey} className="mb-3">
            <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 py-1.5">
              {catLabel}
            </div>
            <div className="space-y-0.5">
              {defs.map((def) => (
                <PaletteItem key={def.type} def={def} />
              ))}
            </div>
          </div>
        )
      })}
    </div>
  )
}
