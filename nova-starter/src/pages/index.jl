using ..Nova

include("../components/header.jl")

function handler()
	header_html = header()

	return Nova.render(
		"""
	$header_html
	<div class='container fade-in'>
		<h1>Welcome to Nova.jl!</h1>
		<p>This is a simple web application built with Nova.jl framework.</p>
		
		<h2>What is Nova.jl?</h2>
		<p>
			The Nova APP project is an unfinished prototype of a web framework built with Julia.
			This framework allows you to create frontend apps using only Julia and HTML.
			You can make HTTP requests, integrate with an API, create games, blogs, social networks,
			and much more.
		</p>
		<div>
			<h2>Auto Features:</h2>
			<ul>
				<li><strong>Auto CSS/SCSS loading</strong> - All files in /styles are loaded automatically</li>
				<li><strong>Static file serving</strong> - Files in /public are served automatically</li>
				<li><strong>Hot reload</strong> - Changes are reflected instantly</li>
				<li><strong>Zero configuration</strong> - Just create files and they work!</li>
			</ul>
		</div>
		
		<div class="center">
			<a
			 class="btn"
			 href="https://github.com/otsuki-dev/nova.jl"
			 target="_blank" rel="noopener noreferrer">
			 Git Repository
			 </a>
		</div>
	</div>
	""",
	)
end
