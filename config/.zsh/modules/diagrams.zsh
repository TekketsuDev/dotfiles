# ================================
# ~/.zsh/modules/diagrams.zsh
# ================================
json_tree() {
  if [ -t 0 ] && [ -n "$1" ]; then
    jq -r '
      def tree(indent):
        to_entries[] |
        "\(indent)\(.key):" +
        (if (.value | type) == "object"
         then "\n" + (.value | tree(indent + "  "))
         else " \(.value)"
         end);
      . | tree("")
    ' "$1"
  else
    jq -r '
      def tree(indent):
        to_entries[] |
        "\(indent)\(.key):" +
        (if (.value | type) == "object"
         then "\n" + (.value | tree(indent + "  "))
         else " \(.value)"
         end);
      . | tree("")
    '
  fi
}

yaml_tree() {
  if [ -t 0 ] && [ -n "$1" ]; then

  else
    yq eval -o=json - | json_tree
  fi
}


ascii_tree_hierarchy_pretty() {
  jq -r '
    def walk(path):
      if type == "object" then
        to_entries[] | .key as $k | .value | walk(path + [$k])
      elif type == "array" then
        to_entries[] | .key as $k | .value | walk(path + [($k | tostring)])
      else
        [path]
      end;

    . as $in | walk([]) | map(join("."))[]
  ' "${1:-/dev/stdin}" | awk '
    function repeat(str, n,   out) {
      out = ""
      for (i = 0; i < n; i++) out = out str
      return out
    }

    function draw_box(key, indent) {
      pad = repeat("  ", indent)
      line = repeat("─", length(key) + 2)
      print pad "┌" line "┐"
      print pad "│ " key " │"
      print pad "└" line "┘"
    }

    {
      split($0, parts, /\./)
      path = ""
      for (i = 1; i <= length(parts); i++) {
        key = parts[i]
        indent = i - 1
        path = (i == 1 ? key : path "." key)
        if (!(path in drawn)) {
          if (i > 1) {
            conn_pad = repeat("  ", indent - 1)
            print conn_pad "│"
            print conn_pad "└───┐"
          }
          draw_box(key, indent)
          drawn[path] = 1
        }
      }
    }
  '
}
 ascii_tree_hierarchy_pr() {
  jq -r '
    def walk(path):
      if type == "object" then
        to_entries[] | .key as $k | .value | walk(path + [$k])
      elif type == "array" then
        to_entries[] | .key as $k | .value | walk(path + [($k | tostring)])
      else
        [path]
      end;

    . as $in | walk([]) | map(join("."))[]
  ' "${1:-/dev/stdin}" | awk '
    function repeat(str, n,   out) {
      out = ""
      for (i = 0; i < n; i++) out = out str
      return out
    }

    function draw_box(key, indent) {
      pad = repeat("  ", indent)
      line = repeat("─", length(key) + 2)
      print pad "┌" line "┐"
      print pad "│ " key " │"
      print pad "└" line "┘"
    }

    {
      split($0, parts, /\./)
      full_path = ""
      for (i = 1; i <= length(parts); i++) {
        key = parts[i]
        indent = i - 1
        full_path = (i == 1 ? key : full_path "." key)

        if (!(full_path in drawn)) {
          drawn[full_path] = 1

          # dibujar conexión solo si es un hijo
          if (i > 1) {
            conn_pad = repeat("  ", indent - 1)
            print conn_pad "│"
            print conn_pad "└───┐"
          }

          draw_box(key, indent)
        }
      }
    }
  '
}
