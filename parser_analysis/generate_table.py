import re
import sys

def parse_y_output(filepath):
    terminals = set()
    non_terminals = set()
    states = {}
    current_state = None

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            
            # Match State
            if line.startswith('State '):
                current_state = int(line.split()[1])
                states[current_state] = {'action': {}, 'goto': {}, 'default': None}
                continue

            if current_state is None: continue

            # Match Shift
            m_shift = re.match(r'^(\S+)\s+shift, and go to state (\d+)', line)
            if m_shift:
                sym, tgt = m_shift.groups()
                terminals.add(sym)
                if sym not in states[current_state]['action']:
                    states[current_state]['action'][sym] = []
                # Append to list to support multiple actions
                states[current_state]['action'][sym].append(f"s{tgt}")
                continue

            # Match Reduce
            m_reduce = re.match(r'^(\S+)\s+\[?reduce using rule (\d+).*\]?', line)
            if m_reduce:
                sym, rule = m_reduce.groups()
                if sym == '$default':
                    states[current_state]['default'] = f"r{rule}"
                else:
                    terminals.add(sym)
                    if sym not in states[current_state]['action']:
                        states[current_state]['action'][sym] = []
                    action_str = f"r{rule}"
                    if action_str not in states[current_state]['action'][sym]:
                        states[current_state]['action'][sym].append(action_str)
                continue

            # Match Goto
            m_goto = re.match(r'^(\S+)\s+go to state (\d+)', line)
            if m_goto:
                sym, tgt = m_goto.groups()
                non_terminals.add(sym)
                states[current_state]['goto'][sym] = f"{tgt}"
                continue

            # Match Accept
            if '$default  accept' in line or '$end  accept' in line or ('accept' in line and '$end' in line):
                terminals.add('$')
                if '$' not in states[current_state]['action']:
                    states[current_state]['action']['$'] = []

                if 'acc' not in states[current_state]['action']['$']:
                    states[current_state]['action']['$'].append('acc')

    if '$end' in terminals:
        terminals.remove('$end')
        terminals.add('$')
    if 'error' in terminals:
        terminals.remove('error')

    return states, sorted(list(terminals)), sorted(list(non_terminals))

def write_html(states, terminals, non_terminals, output_file="parsing_table_new.html"):
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>YAPL-S LALR(1) Parsing Table</title>
        <style>
            body { font-family: sans-serif; margin: 20px; background-color: #f4f4f9; }
            .table-container { 
                max-width: 100%; max-height: 80vh; overflow: auto; 
                border: 1px solid #ccc; box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            }
            table { border-collapse: collapse; width: max-content; background: white; }
            th, td { border: 1px solid #ddd; padding: 6px 10px; text-align: center; font-size: 13px; }
            th { background-color: #2c3e50; color: white; position: sticky; top: 0; z-index: 2; }
            th.state-col { position: sticky; left: 0; z-index: 3; background-color: #1a252f; }
            td.state-col { position: sticky; left: 0; background-color: #ecf0f1; font-weight: bold; z-index: 1; }
            
            /* Action Colors */
            .shift { color: #2980b9; font-weight: bold; background-color: #e8f4f8; }
            .reduce { color: #c0392b; font-weight: bold; background-color: #fceceb; }
            .goto { color: #8e44ad; font-weight: bold; background-color: #f5eef8; }
            .acc { color: white; background-color: #27ae60; font-weight: bold; }
            
            /* Conflict Highlight Color */
            .conflict { color: white; background-color: #e74c3c; font-weight: bold; border: 2px solid #c0392b; animation: pulse 2s infinite; }
            
            @keyframes pulse {
                0% { background-color: #e74c3c; }
                50% { background-color: #ff7675; }
                100% { background-color: #e74c3c; }
            }
            
            tr:hover td { filter: brightness(0.95); }
        </style>
    </head>
    <body>
        <h2>YAPL-S LALR(1) Parsing Table</h2>
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th class="state-col">State</th>
    """
    
    for t in terminals: html_content += f"<th>{t}</th>"
    for nt in non_terminals: html_content += f"<th>{nt}</th>"
    html_content += "</tr></thead><tbody>"

    for state_idx in range(max(states.keys()) + 1):
        if state_idx not in states: continue
        state_data = states[state_idx]
        html_content += f"<tr><td class='state-col'>{state_idx}</td>"
        
        # Action columns
        for t in terminals:
            yacc_t = '$end' if t == '$' else t
            actions = state_data['action'].get(yacc_t, state_data['action'].get(t, []))
            
            # Apply default reduction if cell is empty
            if not actions and state_data['default']:
                actions = [state_data['default']]
                
            if len(actions) > 1:
                # CONFLICT: Multiple actions found!
                cls = "conflict"
                val = "<br>".join(actions)
            elif len(actions) == 1:
                # Standard deterministic cell
                val = actions[0]
                cls = "shift" if val.startswith('s') else "reduce" if val.startswith('r') else "acc" if val == "acc" else ""
            else:
                val = ""
                cls = ""
                
            html_content += f"<td class='{cls}'>{val}</td>"
            
        # Goto columns
        for nt in non_terminals:
            val = state_data['goto'].get(nt, '')
            cls = "goto" if val else ""
            html_content += f"<td class='{cls}'>{val}</td>"
            
        html_content += "</tr>"

    html_content += "</tbody></table></div></body></html>"

    with open(output_file, 'w') as f:
        f.write(html_content)

if __name__ == "__main__":
    import sys
    target_file = sys.argv[1] if len(sys.argv) > 1 else 'yapl_s_new.output'
    try:
        states, terminals, non_terminals = parse_y_output(target_file)
        write_html(states, terminals, non_terminals)
        print(f"SUCCESS!")
    except Exception as e:
        print("Error reading file:", e)