include("routines.jl")

#= Compute the two Hamiltonians (upstream and downstream)
as sampled from the Gibbs0 distribution. =# 
function main(nmodes::Int, nsamples::Int, invtemp::Float64, 
		E0::Float64, D0::Float64, suffix::AbstractString)
	savemicro = true
	cput0 = time()
	println("\n\n")
	# Sample from a Gibbs distribution.
	H3vec,H2vec,uhacc = gibbs(nmodes,nsamples,invtemp,E0,D0,savemicro)
	naccsamples = endof(H3vec)
	# Convert each accepted uhat to physical space for analysis.
	uacc = getuacc(uhacc)
	uhavg = getuhavg(uhacc)
	cputime = time()-cput0
	# Write Hamiltonian data to a file.
	println("\nWriting data to output file.")
	hamlabel = "# Hamiltonian data: nsamples, nmodes, invtemp, E0, D0, H3, H2, uhavg"
	hamdata = [hamlabel; naccsamples; nmodes; invtemp; E0; D0; H3vec; H2vec; uhavg]
	hamfile = string("../SamplingData/hamdata",suffix,".txt")
	writedata(hamdata, hamfile)
	# Write uacc data to a file.
	#udata = [uacc [real(uhacc); imag(uhacc)] ]
	ufile = string("../SamplingData/udata",suffix,".txt")
	writedata(uacc, ufile)
	# Print the final CPU time.
	println("The CPU time is ", signif(cputime/60,2), " minutes.")
	return
end

main(10, 1*10^6, -0.0, 4., 1.0, "up")
#main(10, 2*10^7, -0.3, 4., 1.0, "up")	#0.078%
#main(10, 2*10^7, -0.3, 4., 0.5, "dn") 	#0.074%
