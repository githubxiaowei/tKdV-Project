#---------- Basic Stuff ----------#
using Distributions
using Roots
using DelimitedFiles
using LinearAlgebra
using FFTW
using JLD
using Plots
using LaTeXStrings
#---------------------------------#

#---------- Real FFT Routines ----------#
#= Compute the FFT between physical and spectral space assuming
1) the signal uu is real and 2) uu has zero mean (i.e. momentum M=0)
Note: uu has length npoints = 2*nmodes or 2*nmodes + 1. =#
#= Valid choices for npoints are 2*nmodes or 2*nmodes+1, 
but I need a function to keep my usage consistent.
Note: for H3test npts = 2*modes is slightly more accurate. =#
function npoints(nmodes::Int)
	return 2*nmodes
end
#= Basic realfft to go from uu to uhat. =#
function realfft(uu::Vector{Float64})
	uhat = rfft(uu)/length(uu)
	@assert(abs(uhat[1])/maximum(abs,uhat) < 1e-6) 
	return uhat[2:end]
end
#= Basic irealfft to go from uhat to uu (no upsampling). =#
function irealfft(uhat::Vector{Complex{Float64}})
	nmodes = length(uhat)
	uu = irfft([0; uhat], npoints(nmodes))
	return uu*length(uu)
end
#= Upsampled version of irealfft. =#
function ifftup(uhat::Vector{Complex{Float64}})
	uhat = [uhat; zeros(eltype(uhat), length(uhat))]
	return irealfft(uhat)
end
#---------------------------------------#

#---------- Hamiltonian Routines ----------#
#= In all routines, the physical signal is assumed to be real 
with zero momentum, M = int u dx = 0. Therefore, the Fourier transform 
only requires the modes k=1,...,nmodes. The negative modes are given 
by the complex conjugates (CC), and the k=0 mode vanishes due to M=0. =#
#---------- Low-level Hamiltonian Routines ----------#
#= Compute the energy, E = 1/2 int u^2 dx. =#
function energy(uhat::Vector{Complex{Float64}})
	return 2*pi*norm(uhat)^2
end
# Compute H2 = 1/2 int u_x^2 dx
function ham2(uhat::Vector{Complex{Float64}})
	kvec = 1:length(uhat)
	uxhat = im*kvec.*uhat
	return energy(uxhat)
end
#= Compute H3 using FFT to physical space, H3 = 1/6 int u^3 dx. =#
function ham3(uhat::Vector{Complex{Float64}})
	uu = ifftup(uhat)
	return 1/6 * sum(uu.^3) * 2*pi/length(uu)
end
#---------- High-level Hamiltonian Routines ----------#
# Sampled state
struct RandList
	rvar::Array; H2::Vector; H3::Vector; 
end
# List of constants
struct ConstantList
	C2::Float64; C3::Float64; D0::Float64
end
#= Compute the constanst C2 and C3. =#
function C2C3(eps0::Float64, del0::Float64, lamfac::Int)
	C2 = (2/3) * pi^2 * del0/lamfac^2
	C3 = 1.5 * sqrt(pi) * eps0/del0
	return C2,C3
end

#= Compute the Hamiltonian. H3 and H2 are real and can be numbers or vectors. =#
function hamiltonian(H2, H3, C2, C3, D0)
	return C2*D0^(1/2)*H2 - C3*D0^(-3/2)*H3
end
#= Compute the upstream Hamiltonian.=#
function hamup(rr::RandList, cc::ConstantList)
	return hamiltonian(rr.H2, rr.H3, cc.C2, cc.C3, 1.)
end
#= Compute the downstream Hamiltonian.=#
function hamdn(rr::RandList, cc::ConstantList)
	return hamiltonian(rr.H2, rr.H3, cc.C2, cc.C3, cc.D0)
end
#= Mean of ham under Gibbs measure hamgibbs. =#
function meanham(ham, hamgibbs, theta)
	return dot(exp.(-theta*hamgibbs), ham) / sum(exp.(-theta*hamgibbs))
end
#---------------------------------------#

#---------- Sampling Routines ----------#
#= Get uhat from the array of random values. =#
function getuhat(rvar::Array{Float64}, nn::Int)
	uhat = rvar[:,1,nn]+im*rvar[:,2,nn]
	return uhat/sqrt(energy(uhat))
end
#= Sample from a uniform distribution on the hypershpere E=1. =#
function uniform_sample(nmodes::Int, nsamples::Int, savemicro::Bool)
	rvar = randn(nmodes,2,nsamples)
	H2vec, H3vec = [zeros(Float64,nsamples) for nn=1:2]
	## Later parralelize this step. #@parallel
	# Compute H3 and H2 for each sample in a parallel for loop.
	for nn=1:nsamples
		uhat = getuhat(rvar,nn)
		H2vec[nn] = ham2(uhat); H3vec[nn] = ham3(uhat)
		if mod(nn, 10^4) == 0
			println("Uniform sampling ", 
				round(100*nn/nsamples,sigdigits=3), "% completed.")
		end
	end
	savemicro ? rsave = Float32.(rvar) : rsave = []
	savefile = string("rand-", string(nmodes), "-", string(nsamples), ".jld")
	save(savefile, "rr", RandList(rsave,H2vec,H3vec),
		"nmodes", nmodes, "nsamples", nsamples)
	return
end
#---------------------------------------#




#---------- New ----------#
#= Compute the skewness of the displacement, u or eta.
Note: the skewness of u (dimless) is the same as the skewness of eta (dimensional) =#
function skewu(H3, hamgibbs, theta)
	meanH3 =  dot(exp.(-theta*hamgibbs), H3) / sum(exp.(-theta*hamgibbs))
	skewu = 3*pi^(1/2)*meanH3
	return skewu
end


