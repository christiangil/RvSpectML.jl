"""
Delegates loading of code for different interpolation aglorithms (in their own modules).
Also wraps these modules, so they're called easily by `pack_chunk_list_timeseries_to_matrix`.

Author: Eric Ford
Created: August 2020
"""


include("linear.jl")
import .LinearInterpolation
export interp_chunk_to_grid_linear!

include("sinc.jl")
using .SincInterpolation
export interp_chunk_to_grid_sinc!

include("gp.jl")
import .GPInterpolation
export interp_chunk_to_grid_gp!



"""
   interp_chunk_to_grid_linear!( flux_out, var_out, chunk_of_spectrum, wavelengths )
Return spectra interpolated onto a grid of points using linear interpolation.
# Arguments:
- flux_out::AbstractArray
- var_out::AbstractArray
- chunk::AbstractChunkOfSpectrum
- grid::AbstractRange or AbstractArray
# Alters
- flux_out
- var_out::AbstractArray
# Returns
- flux_out
"""
function interp_chunk_to_shifted_grid_linear!( flux_out::AbstractArray{T1,1}, var_out::AbstractArray{T2,1}, chunk::AC, grid::AR, boost_factor::Real ) where {
    T1<:Real, T2<:Real, AC<:AbstractChuckOfSpectrum, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    @assert size(flux_out) == size(var_out)
    @assert size(flux_out) == size(grid)
    lin_interp_flux = extrapolate(LinearInterpolation.make_interpolator_linear_flux(chunk))
    lin_interp_var = extrapolat(LinearInterpolation.make_interpolator_linear_var(chunk))
    flux_out .= lin_interp_flux(grid.*boost_factor)
    var_out .= lin_interp_var(grid.*boost_factor)
    return flux_out
end

function interp_chunk_to_shifted_grid_linear( chunk::AC, grid::AR, boost_factor::Real ) where {  AC<:AbstractChuckOfSpectrum, T2<:Real, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    flux_out = Array{Float64,1}(undef,length(grid))
    var_out = Array{Float64,1}(undef,length(grid))
    interp_chunk_to_shifted_grid_linear!(flux_out, var_out, chunk, grid, boost_factor)
    return (flux=flux_out, var=var_out)
end

function interp_chunk_to_grid_linear!( flux_out::AbstractArray{T1,1}, var_out::AbstractArray{T2,1}, chunk::AC, grid::AR ) where {
    T1<:Real, T2<:Real, AC<:AbstractChuckOfSpectrum, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    @assert size(flux_out) == size(var_out)
    @assert size(flux_out) == size(grid)
    lin_interp_flux = LinearInterpolation.make_interpolator_linear_flux(chunk)
    lin_interp_var = LinearInterpolation.make_interpolator_linear_var(chunk)
    flux_out .= lin_interp_flux(grid)
    var_out .= lin_interp_var(grid)
    return flux_out
end

function interp_chunk_to_grid_linear( chunk::AC, grid::AR ) where {  AC<:AbstractChuckOfSpectrum, T2<:Real, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    flux_out = Array{Float64,1}(undef,length(grid))
    var_out = Array{Float64,1}(undef,length(grid))
    interp_chunk_to_grid_linear!(flux_out, var_out, chunk, grid)
    return (flux=flux_out, var=var_out)
end

"""
   interp_chunk_to_grid_sinc!( flux_out, var_out, chunk_of_spectrum, wavelengths )
Return spectra interpolated onto a grid of points using sinc interpolation.
# Arguments:
- flux_out::AbstractArray
- var_out::AbstractArray
- chunk::AbstractChunkOfSpectrum
- grid::AbstractRange or AbstractArray
# Alters
- flux_out
- var_out::AbstractArray
# Returns
- flux_out
"""
function interp_chunk_to_shifted_grid_sinc!( flux_out::AbstractArray{T1,1}, var_out::AbstractArray{T2,1}, chunk::AC, grid::AR, boost_factor::Real; Filter::AbstractVector = zeros(0) ) where {
    T1<:Real, T2<:Real, AC<:AbstractChuckOfSpectrum, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    @assert size(flux_out) == size(var_out)
    @assert size(flux_out) == size(grid)
    if length(Filter) >= 1
        flux_out .= SincInterpolation.spectra_interpolate(grid.* boost_factor,chunk.λ,chunk.flux, Filter=Filter)
        var_out .= SincInterpolation.spectra_interpolate(grid.*boost_factor,chunk.λ ,chunk.var, Filter=Filter)
    else
        flux_out .= SincInterpolation.spectra_interpolate(grid.* boost_factor,chunk.λ ,chunk.flux)
        var_out .= SincInterpolation.spectra_interpolate(grid .* boost_factor,chunk.λ,chunk.var)
    end
    return flux_out
end

function interp_chunk_to_shifted_grid_sinc( chunk::AC, grid::AR, boost_factor::Real; Filter::AbstractVector = zeros(0) ) where {  AC<:AbstractChuckOfSpectrum, T2<:Real, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    flux_out = Array{Float64,1}(undef,length(grid))
    var_out = Array{Float64,1}(undef,length(grid))
    if length(Filter) >= 1
        interp_chunk_to_shifted_grid_sinc!(flux_out, var_out, chunk, grid, boost_factor, Filter=Filter)
    else
        interp_chunk_to_shifted_grid_sinc!(flux_out, var_out, chunk, grid, boost_factor)
    end
    return (flux=flux_out, var=var_out)
end

function interp_chunk_to_grid_sinc!( flux_out::AbstractArray{T1,1}, var_out::AbstractArray{T2,1}, chunk::AC, grid::AR ) where {
    T1<:Real, T2<:Real, AC<:AbstractChuckOfSpectrum, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    @assert size(flux_out) == size(var_out)
    @assert size(flux_out) == size(grid)
    flux_out .= SincInterpolation.spectra_interpolate(grid,chunk.λ,chunk.flux)
    var_out .= SincInterpolation.spectra_interpolate(grid,chunk.λ,chunk.var)
    return flux_out
end

function interp_chunk_to_grid_sinc( chunk::AC, grid::AR ) where {  AC<:AbstractChuckOfSpectrum, T2<:Real, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    flux_out = Array{Float64,1}(undef,length(grid))
    var_out = Array{Float64,1}(undef,length(grid))
    interp_chunk_to_grid_sinc!(flux_out, var_out, chunk, grid)
    return (flux=flux_out, var=var_out)
end

"""
   interp_chunk_to_grid_gp!( flux_out, var_out, chunk_of_spectrum, wavelengths )
Return spectra interpolated onto a grid of points using Gaussian Process interpolation.
# Arguments:
- flux_out::AbstractArray
- var_out::AbstractArray
- chunk::AbstractChunkOfSpectrum
- grid::AbstractRange or AbstractArray
# Alters
- flux_out
- var_out::AbstractArray
# Returns
- flux_out

NOTE:  Using own GP code for now, since include predicting derivatives and can minimize unnecessary dependancies.  We may need to
revisit this if we want improved speed
"""

function interp_chunk_to_shifted_grid_gp!( flux_out::AA1, var_out::AA2, chunk::AC, grid::AR, boost_factor::Real ) where { T1<:Real, AA1<:AbstractArray{T1,1}, T2<:Real, AA2<:AbstractArray{T2,1}, AC<:AbstractChuckOfSpectrum, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    @assert size(flux_out) == size(var_out)
    @assert size(flux_out) == size(grid)
    rho = 2*5000/speed_of_light_mps * mean(chunk.λ)
    sigmasq_kernel = 0.25 # Float64(mean(chunk.var))
    println(" rho = ", rho, "  σ²_kernel = ", sigmasq_kernel)
    flux_out .= GPInterpolation.predict_mean(chunk.λ.*boost_factor, chunk.flux, grid, sigmasq_obs = chunk.var, kernel = GPs.matern52_sparse_kernel, rho=rho, sigmasq_cor=sigmasq_kernel ) # 	sigmasq_cor=1.0, rho=1
    # TODO: Update var_out to actually use the right GP or at least do something more sensible
    #var_out .= GPInterpolation.predict_mean(chunk.λ, chunk.var, grid, sigmasq_obs = chunk.var, kernel = GPs.matern52_sparse_kernel, rho=5000/speed_of_light_mps) # 	sigmasq_cor=1.0, rho=1
    return flux_out
end

function interp_chunk_to_shifted_grid_gp( chunk::AC, grid::AR, boost_factor::Real ) where {  AC<:AbstractChuckOfSpectrum, T2<:Real, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    flux_out = Array{Float64,1}(undef,length(grid))
    var_out = Array{Float64,1}(undef,length(grid))
    interp_chunk_to_grid_gp!(flux_out, var_out, chunk, grid, boost_factor=boost_factor)
    return (flux=flux_out, var=var_out)
end

function interp_chunk_to_grid_gp!( flux_out::AA1, var_out::AA2, chunk::AC, grid::AR ) where { T1<:Real, AA1<:AbstractArray{T1,1}, T2<:Real, AA2<:AbstractArray{T2,1}, AC<:AbstractChuckOfSpectrum, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    @assert size(flux_out) == size(var_out)
    @assert size(flux_out) == size(grid)
    rho = 2*5000/speed_of_light_mps * mean(chunk.λ)
    sigmasq_kernel = 0.25 # Float64(mean(chunk.var))
    println(" rho = ", rho, "  σ²_kernel = ", sigmasq_kernel)
    flux_out .= GPInterpolation.predict_mean(chunk.λ, chunk.flux, grid, sigmasq_obs = chunk.var, kernel = GPs.matern52_sparse_kernel, rho=rho, sigmasq_cor=sigmasq_kernel ) # 	sigmasq_cor=1.0, rho=1
    # TODO: Update var_out to actually use the right GP or at least do something more sensible
    #var_out .= GPInterpolation.predict_mean(chunk.λ, chunk.var, grid, sigmasq_obs = chunk.var, kernel = GPs.matern52_sparse_kernel, rho=5000/speed_of_light_mps) # 	sigmasq_cor=1.0, rho=1
    return flux_out
end

function interp_chunk_to_grid_gp( chunk::AC, grid::AR ) where {  AC<:AbstractChuckOfSpectrum, T2<:Real, AR<:Union{AbstractRange,AbstractArray{T2,1}} }
    flux_out = Array{Float64,1}(undef,length(grid))
    var_out = Array{Float64,1}(undef,length(grid))
    interp_chunk_to_grid_gp!(flux_out, var_out, chunk, grid)
    return (flux=flux_out, var=var_out)
end




# Wrapper code to deal with weird data structures
function pack_chunk_list_timeseries_to_matrix(timeseries::ACLT, chunk_grids::Union{AR,AAV}; alg::Symbol = :Linear,
    oversample_factor::Real = 1, verbose::Bool = false ) where {
        ACLT<:AbstractChunkListTimeseries, RT<:AbstractRange, AR<:AbstractArray{RT,1}, T<:Real, AV<:AbstractVector{T}, AAV<:AbstractArray{AV,1} }
    @assert alg == :Linear || alg == :GP  || alg == :Sinc # TODO: Eventually move to traits-based system?
    num_obs = length(timeseries)
    num_λ = sum(length.(chunk_grids))
    flux_matrix = Array{Float64,2}(undef,num_λ,num_obs)
    var_matrix = Array{Float64,2}(undef,num_λ,num_obs)
    λ_vec = Array{Float64,1}(undef,num_λ)
    chunk_map = Array{UnitRange{Int64}}(undef,length(chunk_grids))

    if (alg == :GP) && (maximum(length.(chunk_grids))>1024)
        @error "Don't use GPs with more than 1024 points in a chunk until implement more efficient factorization."
    end
    if alg == :Sinc    # Setup workspace for Sync.  TODO: Put into functor
        filter_size=23
        kaiserB=13
        sinc_filter = SincInterpolation.create_filter_curve(filter_size*21; filter_size=filter_size, kaiserB=kaiserB)
    end
    for t in 1:num_obs
       idx_start = 0
       for c in 1:length(chunk_grids)
           idx = (idx_start+1):(idx_start+length(chunk_grids[c]))
           if verbose
               flush(stdout);  println("t= ",t, " c= ",c," idx= ", idx, " size(flux)= ",size(flux_matrix))
           end
           if alg == :Linear
               interp_chunk_to_grid_linear!(view(flux_matrix,idx,t), view(var_matrix,idx,t), timeseries.chunk_list[t].data[c], chunk_grids[c])
           elseif alg == :Sinc
               interp_chunk_to_grid_sinc!(view(flux_matrix,idx,t), view(var_matrix,idx,t), timeseries.chunk_list[t].data[c], chunk_grids[c], Filter=sinc_filter)
           elseif alg == :GP
               interp_chunk_to_grid_gp!(view(flux_matrix,idx,t), view(var_matrix,idx,t), timeseries.chunk_list[t].data[c], chunk_grids[c])
           end
           if t == 1
               λ_vec[idx] .= chunk_grids[c]
               chunk_map[c] = idx
           end
           idx_start += length(chunk_grids[c])
       end
    end
    var_matrix .*= sqrt(oversample_factor)
    return SpectralTimeSeriesCommonWavelengths(λ_vec,flux_matrix,var_matrix,chunk_map, Generic1D() )
end


# Wrapper code to deal with weird data structures
function pack_shifted_chunk_list_timeseries_to_matrix(timeseries::ACLT, chunk_grids::Union{AR,AAV}; alg::Symbol = :Linear,
    oversample_factor::Real = 1, remove_rv_est::Bool = true, verbose::Bool = false ) where {
        ACLT<:AbstractChunkListTimeseries, RT<:AbstractRange, AR<:AbstractArray{RT,1}, T<:Real, AV<:AbstractVector{T}, AAV<:AbstractArray{AV,1} }
    @assert alg == :Linear || alg == :GP  || alg == :Sinc # TODO: Eventually move to traits-based system?
    num_obs = length(timeseries)
    num_λ = sum(length.(chunk_grids))
    flux_matrix = Array{Float64,2}(undef,num_λ,num_obs)
    var_matrix = Array{Float64,2}(undef,num_λ,num_obs)
    λ_vec = Array{Float64,1}(undef,num_λ)
    chunk_map = Array{UnitRange{Int64}}(undef,length(chunk_grids))
    if remove_rv_est
        @assert haskey(first(timeseries.metadata),:rv_est)
    end
    if (alg == :GP) && (maximum(length.(chunk_grids))>1024)
        @error "Don't use GPs with more than 1024 points in a chunk until implement more efficient factorization."
    end
    if alg == :Sinc    # Setup workspace for Sync.  TODO: Put into functor
        filter_size=23
        kaiserB=13
        sinc_filter = SincInterpolation.create_filter_curve(filter_size*21; filter_size=filter_size, kaiserB=kaiserB)
    end
    for t in 1:num_obs
       idx_start = 0
       boost_factor = remove_rv_est ? calc_doppler_factor(timeseries.metadata[t][:rv_est]) : 1.0
       for c in 1:length(chunk_grids)
           idx = (idx_start+1):(idx_start+length(chunk_grids[c]))
           if verbose
               flush(stdout);  println("t= ",t, " c= ",c," idx= ", idx, " size(flux)= ",size(flux_matrix))
           end
           if alg == :Linear
               interp_chunk_to_shifted_grid_linear!(view(flux_matrix,idx,t), view(var_matrix,idx,t), timeseries.chunk_list[t].data[c], chunk_grids[c], boost_factor )
           elseif alg == :Sinc
               interp_chunk_to_shifted_grid_sinc!(view(flux_matrix,idx,t), view(var_matrix,idx,t), timeseries.chunk_list[t].data[c], chunk_grids[c], boost_factor, Filter=sinc_filter )
           elseif alg == :GP
               interp_chunk_to_shifted_grid_gp!(view(flux_matrix,idx,t), view(var_matrix,idx,t), timeseries.chunk_list[t].data[c], chunk_grids[c], boost_factor)
           end
           if t == 1
               λ_vec[idx] .= chunk_grids[c]
               chunk_map[c] = idx
           end
           idx_start += length(chunk_grids[c])
       end
    end
    var_matrix .*= sqrt(oversample_factor)
    return SpectralTimeSeriesCommonWavelengths(λ_vec,flux_matrix,var_matrix,chunk_map, Generic1D() )
end
