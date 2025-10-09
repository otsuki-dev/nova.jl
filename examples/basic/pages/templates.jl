using ..Nova

include("../components/header.jl")

function chess_board_html()
	# A simple static chessboard rendered in HTML. For a more interactive game,
	# you'd wire these cells to server-side Julia handlers or client-side JS.
	squares = """
	<style>
	.chessboard { display: grid; grid-template-columns: repeat(8, 48px); grid-gap: 0; }
	.square { width:48px; height:48px; display:flex; align-items:center; justify-content:center; font-size:24px; }
	.white { background:#f0d9b5; }
	.black { background:#b58863; }
	.piece { pointer-events:none; }
	</style>
	<div class="chessboard">
	"""

	board = [
		"r", "n", "b", "q", "k", "b", "n", "r",
		"p", "p", "p", "p", "p", "p", "p", "p",
		"", "", "", "", "", "", "", "",
		"", "", "", "", "", "", "", "",
		"", "", "", "", "", "", "", "",
		"", "", "", "", "", "", "", "",
		"P", "P", "P", "P", "P", "P", "P", "P",
		"R", "N", "B", "Q", "K", "B", "N", "R",
	]

	for rank in 0:7
		for file in 0:7
			idx = rank * 8 + file + 1
			piece = board[idx]
			colorclass = (((rank + file) % 2) == 0) ? "white" : "black"
			cell = "<div class=\"square $colorclass\">$(piece == "" ? "&nbsp;" : "<span class=\"piece\">$piece</span>")</div>"
			squares *= cell
		end
	end

	squares *= "</div>"
	# add a container id for JS to mount interactive board
	return "<div id=\"chess-app\">" * squares * "</div>"
end

function handler()
	header_html = header()
	cb = chess_board_html()

	# Brief Julia example: function that generates legal moves for a knight from a square
	julia_example = """
	```julia
	function knight_moves(pos)
		file = Int(pos[1]) - Int('a') + 1
		rank = parse(Int, pos[2])
		offsets = ((1,2),(2,1),(-1,2),(-2,1),(1,-2),(2,-1),(-1,-2),(-2,-1))
		for (df, dr) in offsets
			f = file + df
			r = rank + dr
			if 1 <= f <= 8 && 1 <= r <= 8
				push!(moves, string(Char('a'+f-1), r))
			end
		end
		return moves
	end
	```
	"""

				# client JS to connect to websocket and handle clicks
				client_js = """
				<script>
				(() => {
					  let state = null;
					  let selected = null;
					  let gameId = null;
					  let usingWS = false;

					function connect() {
						const modeEl = document.querySelector('input[name="mode"]:checked');
						const mode = modeEl ? modeEl.value : 'human';
									try {
										const ws = new WebSocket(`ws://\${location.host}/ws/chess`);
										usingWS = true;
										ws.addEventListener('open', () => {
											ws.send(JSON.stringify({type:'join', mode}));
										});
										ws.addEventListener('message', (e) => {
											const obj = JSON.parse(e.data);
											if (obj.type === 'state') {
												state = obj;
												gameId = obj.id || gameId;
												renderBoard(obj.board);
											}
										});
										ws.addEventListener('close', () => { usingWS = false; setTimeout(connect, 500); });
										window.__nova_ws = ws;
										return;
									} catch (err) {
										usingWS = false;
									}

									// fallback: join via HTTP
									fetch('/api/chess/join', {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({mode})})
										.then(r => r.json()).then(obj => { state = obj; gameId = obj.id; renderBoard(obj.board); })
										.catch(()=>{});
					}

					function renderBoard(board) {
						const app = document.getElementById('chess-app');
						if (!app) return;
						const squares = app.querySelectorAll('.chessboard .square');
						board.forEach((p, i) => {
							squares[i].innerHTML = p === '' ? '&nbsp;' : `<span class='piece'>\${p}</span>`;
						});
					}

					document.addEventListener('click', (ev) => {
						const sq = ev.target.closest('.square');
						if (!sq) return;
						const squares = Array.from(document.querySelectorAll('.chessboard .square'));
						const idx = squares.indexOf(sq);
						if (idx < 0) return;
						const file = String.fromCharCode('a'.charCodeAt(0) + (idx % 8));
						const rank = 8 - Math.floor(idx / 8);
						const coord = `\${file}\${rank}`;
						if (!selected) {
							selected = coord;
							sq.style.outline = '3px solid #36f';
						} else {
							const from = selected;
							const to = coord;
							squares.forEach(s => s.style.outline='');
							selected = null;
											if (usingWS && window.__nova_ws && window.__nova_ws.readyState === WebSocket.OPEN) {
												window.__nova_ws.send(JSON.stringify({type:'move', from, to}));
											} else if (gameId) {
												fetch('/api/chess/move', {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({id:gameId, from, to})})
													.then(r => r.json()).then(obj => { if (obj.state) renderBoard(obj.state); });
											}
						}
					});

					connect();
				})();
				</script>
				"""

	return Nova.render(
		"""
		$header_html
		<div class='container fade-in'>
			<h1>Templates</h1>
			<p>Example templates and small apps you can use as a starting point.</p>

			<h2>Chess (interactive)</h2>
			<p>Play chess here. Choose a mode and click on a square to move (select source then target).</p>
			<div style="margin-bottom:8px;">
				<label><input type="radio" name="mode" value="human" checked> Jogar vs Humano</label>
				<label style="margin-left:12px;"><input type="radio" name="mode" value="ai"> Jogar vs Computador</label>
			</div>
			$cb

			<h3>Julia helper (example)</h3>
			<p>Here's a tiny Julia function that computes knight moves:</p>
			<pre>$julia_example</pre>

			<h3>Progressing this demo</h3>
			<ul>
				<li>Add server endpoints to validate and apply moves.</li>
				<li>Use WebSockets to push board updates to clients.</li>
				<li>Replace piece letters with SVG icons.</li>
			</ul>
			$client_js
		</div>
		""",
	)
end
