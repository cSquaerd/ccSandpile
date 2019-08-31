module ccSandpiles
	import Base.show, Base.maximum, Base.size, Base.+, Base.*
	export Sandpile, topple!, deposit!, fullyTopple!

	mutable struct Sandpile
		# Multidim. Array for holding pile data
		pile::Array{UInt16, 2}
		# Explicit constructor
		function Sandpile(p::Array{t, 2}) where t <: Integer
			local i, j
			local q = similar(p, UInt16)
			for i = 1:size(p)[1]
				for j = 1:size(p)[2]
					q[i, j] = p[i, j]
				end
			end
			new(q)
		end
		# Implicit constructor
		Sandpile(w::Integer, h::Integer, empty::Bool=true) = empty ? new(zeros(UInt16, UInt(w), UInt(h))) : new(Array{UInt16}(undef, UInt(w), UInt(h)))
	end

	function Base.show(io::IO, p::Sandpile)
		local i, j
		local saturated = false
		local colors = [:cyan, :blue, :magenta, :red]
		for i = 1:size(p.pile)[1]
			for j = 1:size(p.pile)[2]
				saturated = p.pile[i,j] > 3
				printstyled(io, p.pile[i,j], bold = saturated, color = !saturated ? colors[p.pile[i,j] + 1] : :light_black)
				j == size(p.pile)[2] ? print('\n') : print(' ')
			end
		end
	end

	function topple!(p::Sandpile, printout::Bool = false)
		local sites = Array{Array{Integer, 1}}(undef, 0)
		local i, j
		for i = 1:size(p.pile)[1]
			for j = 1:size(p.pile)[2]
				p.pile[i,j] > 3 ? push!(sites, [i,j]) : continue
			end
		end
		if length(sites) == 0 return end
		local x, y
		for i = 1:length(sites)
			y = sites[i][1]
			x = sites[i][2]
			p.pile[y, x] -= 4
			if y - 1 > 0 p.pile[y - 1, x] += 1 end
			if y < size(p.pile)[1] p.pile[y + 1, x] += 1 end
			if x - 1 > 0 p.pile[y, x - 1] += 1 end
			if x < size(p.pile)[2] p.pile[y, x + 1] += 1 end
		end
		if printout println(p) end
	end

	deposit!(p::Sandpile, amount::Integer, y::Integer, x::Integer) = p.pile[y, x] += amount

	maximum(p::Sandpile) = maximum(p.pile)

	fullyTopple!(p::Sandpile, printout::Bool = false) = while maximum(p) > 3 topple!(p, printout) end

	size(p::Sandpile) = size(p.pile)

	+(p1::Sandpile, p2::Sandpile) = size(p1) == size(p2) ? Sandpile(p1.pile + p2.pile) : throw(ErrorException("The two piles must be the same dimensions!\n"))

	function *(n::t, p::Sandpile) where t <: Integer
		Sandpile(UInt16(n) * p.pile)
	end
end
