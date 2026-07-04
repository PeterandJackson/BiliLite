import { useCallback, useMemo } from 'react'
import { useComponentStore } from '@/stores/component-store'
import type { StyleProperties, StyleValue } from '@/types'

function SizeRow({
  label,
  value,
  onChange,
}: {
  label: string
  value: StyleValue | undefined
  onChange: (sv: StyleValue) => void
}) {
  const v = value ?? { value: 0, unit: 'px' }
  return (
    <div className="property-row">
      <label className="property-label">{label}</label>
      <div className="flex gap-1 flex-1">
        <input
          type="number"
          className="property-input flex-1"
          value={v.value}
          onChange={(e) => onChange({ ...v, value: Number(e.target.value) || 0 })}
        />
        <select
          className="property-input w-16"
          value={v.unit}
          onChange={(e) => onChange({ ...v, unit: e.target.value as any })}
        >
          <option value="px">px</option>
          <option value="%">%</option>
          <option value="em">em</option>
          <option value="rem">rem</option>
          <option value="auto">auto</option>
        </select>
      </div>
    </div>
  )
}

export function StyleEditor() {
  const selectedIds = useComponentStore((s) => s.selectedIds)
  const components = useComponentStore((s) => s.components)
  const updateComponentStyles = useComponentStore((s) => s.updateComponentStyles)

  const selectedId = useMemo(() => {
    if (selectedIds.size !== 1) return null
    return [...selectedIds][0]
  }, [selectedIds])

  const component = selectedId ? components[selectedId] : null

  const handleChange = useCallback(
    (styles: StyleProperties) => {
      if (!selectedId) return
      updateComponentStyles(selectedId, styles)
    },
    [selectedId, updateComponentStyles]
  )

  if (!component) {
    return (
      <div className="p-4 text-center text-gray-500 text-sm">
        <p>Select a component to edit its styles.</p>
      </div>
    )
  }

  const s = component.styles

  return (
    <div className="p-3 space-y-4">
      {/* Layout Section */}
      <div>
        <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Layout</div>
        <SizeRow
          label="Width"
          value={s.width}
          onChange={(v) => handleChange({ width: v })}
        />
        <SizeRow
          label="Height"
          value={s.height}
          onChange={(v) => handleChange({ height: v })}
        />
        <SizeRow
          label="X"
          value={s.x}
          onChange={(v) => handleChange({ x: v })}
        />
        <SizeRow
          label="Y"
          value={s.y}
          onChange={(v) => handleChange({ y: v })}
        />
      </div>

      {/* Appearance Section */}
      <div>
        <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Appearance</div>

        <div className="property-row">
          <label className="property-label">Background</label>
          <div className="flex gap-1 flex-1">
            <input
              className="property-input flex-1"
              type="text"
              value={s.backgroundColor || ''}
              onChange={(e) => handleChange({ backgroundColor: e.target.value })}
            />
            <input
              type="color"
              value={s.backgroundColor || '#ffffff'}
              onChange={(e) => handleChange({ backgroundColor: e.target.value })}
              className="w-8 h-8 rounded cursor-pointer border border-white/10 bg-transparent"
            />
          </div>
        </div>

        <div className="property-row">
          <label className="property-label">Text Color</label>
          <div className="flex gap-1 flex-1">
            <input
              className="property-input flex-1"
              type="text"
              value={s.color || ''}
              onChange={(e) => handleChange({ color: e.target.value })}
            />
            <input
              type="color"
              value={s.color || '#000000'}
              onChange={(e) => handleChange({ color: e.target.value })}
              className="w-8 h-8 rounded cursor-pointer border border-white/10 bg-transparent"
            />
          </div>
        </div>

        <div className="property-row">
          <label className="property-label">Opacity</label>
          <input
            className="property-input"
            type="number"
            min={0}
            max={1}
            step={0.05}
            value={s.opacity ?? 1}
            onChange={(e) => handleChange({ opacity: Number(e.target.value) })}
          />
        </div>

        <SizeRow
          label="Radius"
          value={s.borderRadius}
          onChange={(v) => handleChange({ borderRadius: v })}
        />
      </div>

      {/* Typography Section */}
      <div>
        <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Typography</div>

        <SizeRow
          label="Font Size"
          value={s.fontSize}
          onChange={(v) => handleChange({ fontSize: v })}
        />

        <div className="property-row">
          <label className="property-label">Weight</label>
          <select
            className="property-input"
            value={s.fontWeight ?? 400}
            onChange={(e) => handleChange({ fontWeight: e.target.value === '400' ? 400 : Number(e.target.value) || e.target.value })}
          >
            <option value="300">Light (300)</option>
            <option value="400">Normal (400)</option>
            <option value="500">Medium (500)</option>
            <option value="600">Semibold (600)</option>
            <option value="700">Bold (700)</option>
            <option value="800">Extra Bold (800)</option>
          </select>
        </div>

        <div className="property-row">
          <label className="property-label">Family</label>
          <input
            className="property-input"
            type="text"
            value={s.fontFamily || ''}
            onChange={(e) => handleChange({ fontFamily: e.target.value })}
            placeholder="system-ui, sans-serif"
          />
        </div>

        <div className="property-row">
          <label className="property-label">Align</label>
          <select
            className="property-input"
            value={s.textAlign || 'left'}
            onChange={(e) => handleChange({ textAlign: e.target.value as any })}
          >
            <option value="left">Left</option>
            <option value="center">Center</option>
            <option value="right">Right</option>
            <option value="justify">Justify</option>
          </select>
        </div>
      </div>

      {/* Border Section */}
      <div>
        <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Border</div>

        <SizeRow
          label="Width"
          value={s.borderWidth}
          onChange={(v) => handleChange({ borderWidth: v })}
        />

        <div className="property-row">
          <label className="property-label">Color</label>
          <div className="flex gap-1 flex-1">
            <input
              className="property-input flex-1"
              type="text"
              value={s.borderColor || ''}
              onChange={(e) => handleChange({ borderColor: e.target.value })}
            />
            <input
              type="color"
              value={s.borderColor || '#000000'}
              onChange={(e) => handleChange({ borderColor: e.target.value })}
              className="w-8 h-8 rounded cursor-pointer border border-white/10 bg-transparent"
            />
          </div>
        </div>

        <div className="property-row">
          <label className="property-label">Style</label>
          <select
            className="property-input"
            value={s.borderStyle || 'solid'}
            onChange={(e) => handleChange({ borderStyle: e.target.value as any })}
          >
            <option value="none">None</option>
            <option value="solid">Solid</option>
            <option value="dashed">Dashed</option>
            <option value="dotted">Dotted</option>
          </select>
        </div>
      </div>

      {/* Shadow Section */}
      <div>
        <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Shadow</div>
        <div className="property-row">
          <label className="property-label">Box Shadow</label>
          <input
            className="property-input"
            type="text"
            value={s.boxShadow || ''}
            onChange={(e) => handleChange({ boxShadow: e.target.value })}
            placeholder="0 2px 8px rgba(0,0,0,0.15)"
          />
        </div>
      </div>

      {/* Z-Index */}
      <div>
        <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Layer</div>
        <div className="property-row">
          <label className="property-label">Z-Index</label>
          <input
            className="property-input"
            type="number"
            value={s.zIndex ?? 0}
            onChange={(e) => handleChange({ zIndex: Number(e.target.value) })}
          />
        </div>
      </div>
    </div>
  )
}
