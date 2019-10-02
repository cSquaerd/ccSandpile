module ccSandpiles
	import Base.show, Base.maximum, Base.size, Base.+, Base.*
	import Images.Gray, Images.colorview, Images.RGB
	import SharedArrays.SharedArray, Distributed.@distributed, Distributed.addprocs
	export Sandpile, topple!, deposit!, fullyTopple!, isStable, toImageGray, toImageRGB, toImageIndexed

	addprocs()

	"Sandpile struct with two constructors"
	mutable struct Sandpile
		# Multidim. Array for holding pile data
		pile::SharedArray{UInt32, 2}
		# Explicit constructor
		function Sandpile(p::Array{t, 2}) where t <: Integer
			local i, j
			local q = convert(SharedArray{UInt32, 2}, similar(p, UInt32))
			for i = 1:size(p)[1]
				for j = 1:size(p)[2]
					q[i, j] = p[i, j]
				end
			end
			new(q)
		end
		# Implicit constructor
		Sandpile(w::Integer, h::Integer, empty::Bool=true) = empty ? new(zeros(UInt16, UInt(w), UInt(h))) : new(SharedArray{UInt32}(UInt(w), UInt(h)))
	end

	"Determine the maximum cell value in a sandpile"
	maximum(p::Sandpile) = maximum(p.pile)
	
	"Determine the dimensions of the sandpile"
	size(p::Sandpile) = size(p.pile)

	"Sandpile show function with color coding"
	function Base.show(io::IO, p::Sandpile)
		local i, j
		local saturated = false
		local colors = [:cyan, :blue, :magenta, :red]
		#Display size is limited to 40x24 as to fit most terminals
		local lowi = size(p)[1] < 24 ? 1 : div(size(p)[1], 2) - 11
		local highi = size(p)[1] < 24 ? size(p)[1] : div(size(p)[1], 2) + 11
		local oversizedi = size(p)[1] > 24
		local lowj = size(p)[2] < 40 ? 1 : div(size(p)[2], 2) - 19
		local highj = size(p)[2] < 40 ? size(p)[2] : div(size(p)[2], 2) + 19
		local oversizedj = size(p)[2] > 40
		for i = lowi:highi
			oversizedi && i == lowi ? println("    …") : print("")
			for j = lowj:highj
				j == lowj ? (oversizedj && i == div(size(p)[1], 2) ? print("… ") : print("  ")) : print("")
				saturated = p.pile[i,j] > 3
				printstyled(p.pile[i,j], bold = saturated, color = !saturated ? colors[p.pile[i,j] + 1] : :light_black)
				j == highj ? (oversizedj && i == div(size(p)[1], 2) ? println(" …") : (println(""))) : print(" ")
			end
			oversizedi && i == highi ? print("    …") : print("")
		end
		oversizedi || oversizedj ? print("\n(Note: Only the center of the sandpile is shown.)") : print("")
	end

	"Do one pass of toppling a sandpile"
	function topple!(p::Sandpile)
		# Determine which cells need to be toppled
		local sites = findall(map(n -> n > 3, p.pile))
		if length(sites) == 0 return p end
		local neighborRelatives = [
			CartesianIndex(-1, 0),
			CartesianIndex(1, 0),
			CartesianIndex(0, -1),
			CartesianIndex(0, 1)
		]
		# Topple cells in need
		for i = 1:length(sites)
			local neighbors = [sites[i], sites[i], sites[i], sites[i]] + neighborRelatives
			p.pile[sites[i]] -= 4
			for n = 1:4
				try p.pile[neighbors[n]] += 1 catch; continue end
			end
		end
		p
	end
	
	"Deposit some sand somewhere on a sandpile"
	function deposit!(p::Sandpile, amount::Integer, y::Integer, x::Integer)
		p.pile[y, x] += amount
		p
	end

	"Repeatedly topple the sandpile until it is stable"
	function fullyTopple!(p::Sandpile)
		while maximum(p) > 3
			topple!(p)
		end
		p
	end

	"Add cell-wise two sandpiles together"
	+(p1::Sandpile, p2::Sandpile) = size(p1) == size(p2) ? Sandpile(p1.pile + p2.pile) : throw(ErrorException("The two piles must be the same dimensions!\n"))

	"Scalar-multiply a sandpile"
	function *(n::Integer, p::Sandpile)
		Sandpile(UInt32(n) * p.pile)
	end

	"Determine if a sandpile is stable"
	isStable(p::Sandpile) = maximum(p) < 4

	"Convert a sandpile to a grayscale image"
	toImageGray(p::Sandpile) = Gray.(map(n -> clamp(round(n / 3, digits = 2), 0.0, 1.0), p.pile))

	"Convert a sandpile to an RGB image"
	function toImageRGB(p::Sandpile, r::Float64 = 0.75, g::Float64 = 0.0, b::Float64 = 1.0)
		local gray = toImageGray(p)
		colorview(RGB, r * gray, g * gray, b * gray)
	end

	"Convert a sandpile to an indexed-RGB image"
	toImageIndexed(
		p::Sandpile,
		colors::Array{RGB{t}, 1} where t <: AbstractFloat = [
			RGB(0.2, 0.2, 0.2),
			RGB(0.25, 0.25, 1.0),
			RGB(1.0, 0.25, 0.25),
			RGB(1.0, 1.0, 0.25)
		]
		) = map(n -> n < 4 ? colors[n + 1] : RGB(0.2, clamp(0.0001 * n, 0.2, 1.0), 0.2), p.pile)
	
	"""
	function toppleOne!(c, p::Sandpile)
		println(c)
		p.pile[c] -= 4;
		local y = c[1]
		local x = c[2]
		println(p.pile[c])
		if y - 1 > 0 p.pile[y - 1, x] += 1 end
		if y < size(p)[1] p.pile[y + 1, x] += 1 end
		if x - 1 > 0 p.pile[y, x - 1] += 1 end
		if x < size(p)[2] p.pile[y, x + 1] += 1 end
	end

	function dTopple!(p::Sandpile)
		local sites = findall(
			pmap(
				n -> n > 3,
				p.pile
			)
		)
		println(sites)
		if length(sites) == 0 println("No sites!"); return p end
		pmap(
			c -> toppleOne!(c, p),
			sites
		)
		p
	end
	"""
end
