module ccSandpiles
	import Base.show
	export Sandpile

	function topple!(p::Sandpile)
		local sites = Array{Array{Integer, 1}}(undef, 0)
		local i, j
		for i = 1:size(p.pile)[1]
			for j = 1:size(p.pile)[2]
				p.pile[i,j] > 3 ? push!(sites, [i,j]) : continue
			end
		end
	end

	mutable struct Sandpile
		# Multidim. Array for holding pile data
		pile::Array{UInt8, 2}
		# Explicit constructor
		function Sandpile(p::Array{UInt8, 2})
			local i, j
			for i = 1:size(p)[1]
				for j = 1:size(p)[2]
					p[i, j] > 3 ? throw(ArgumentError("Initial piles must be fully toppled!\n")) : continue
				end
			end
			new(p)
		end
		# Implicit constructor
		Sandpile(w::Integer, h::Integer, empty::Bool=true) = empty ? new(zeros(UInt8, UInt(w), UInt(h))) : new(Array{UInt8}(undef, UInt(w), UInt(h)))
	end

	function Base.show(io::IO, p::Sandpile)
		local i, j
		for i = 1:size(p.pile)[1]
			for j = 1:size(p.pile)[2]
				printstyled(io, p.pile[i,j], color = :blue)
				j == size(p.pile)[2] ? print('\n') : print(' ')
			end
		end
	end
end