using RvSpectML
using DataFrames, CSV

function ccf_total(order_list_timeseries::AbstractChunkListTimeseries, line_list_df::DataFrame, pipeline::PipelinePlan; recalc::Bool = false,
                  output_fn_suffix::String = "", range_no_mask_change::Real=30e3, ccf_mid_velocity::Real=0.0,
                  mask_scale_factor::Real=1, mask_type::Symbol = :tophat, use_expr::Bool = false )
    if need_to(pipeline,:ccf_total) || recalc
      if verbose println("# Computing CCF.")  end
      @assert !need_to(pipeline,:extract_orders)
      @assert !need_to(pipeline,:clean_line_list_tellurics)
      if mask_type == :tophat
        mask_shape = CCF.TopHatCCFMask(order_list_timeseries.inst, scale_factor=tophap_ccf_mask_scale_factor*mask_scale_factor)
      else
        @error("Requested mask shape (" * string(mask_type) * " not avaliable.")
      end

      line_list = CCF.BasicLineList(line_list_df.lambda, line_list_df.weight)
      ccf_plan = CCF.BasicCCFPlan(mask_shape = mask_shape, line_list=line_list, midpoint=ccf_mid_velocity, range_no_mask_change=range_no_mask_change)
      v_grid = CCF.calc_ccf_v_grid(ccf_plan)
      if use_expr
        @time ccfs = CCF.calc_ccf_chunklist_timeseries_expr(order_list_timeseries, ccf_plan)
      else
        @time ccfs = CCF.calc_ccf_chunklist_timeseries(order_list_timeseries, ccf_plan)
      end
      #mask_shape_expr = CCF.TopHatCCFMask(order_list_timeseries.inst, scale_factor=tophap_ccf_mask_scale_factor*11.0)
      #mask_shape_expr = CCF.GaussianCCFMask(order_list_timeseries.inst, scale_factor=9)
      # Warning:  CCF with a shape other than a tophat is still experimental
      #ccf_plan_expr = CCF.BasicCCFPlan(mask_shape = mask_shape_expr, line_list=line_list, midpoint=ccf_mid_velocity, range_no_mask_change=22e3)
      #@time ccfs_expr = CCF.calc_ccf_chunklist_timeseries_expr(order_list_timeseries, ccf_plan_expr) #, verbose=true)
      #println("# Ratio of max(ccfs_expr)/max(ccfs) = ", mean(maximum(ccfs_expr,dims=1)./maximum(ccfs,dims=1)) )
      #=
      mask_shape_expr2 = RvSpectML.CCF.CosCCFMask(order_list_timeseries.inst, scale_factor=18)   # Why does such a large value help so much?
      ccf_plan_expr2 = RvSpectML.CCF.BasicCCFPlan(mask_shape = mask_shape_expr2, line_list=line_list, midpoint=ccf_mid_velocity)
      @time ccfs_expr2 = RvSpectML.CCF.calc_ccf_chunklist_timeseries_expr(order_list_timeseries, ccf_plan_expr2) #, verbose=true)
      =#
      if save_data(pipeline, :ccf_total)
         CSV.write(joinpath(output_dir,target_subdir * "_ccfs" * output_fn_suffix * ".csv"),Tables.table(ccfs',header=Symbol.(v_grid)))
         #CSV.write(joinpath(output_dir,target_subdir * "_ccfs_expr.csv"),Tables.table(ccfs_expr',header=Symbol.(v_grid)))
      end
      set_cache!(pipeline, :ccf_total, (ccfs=ccfs, v_grid=v_grid) )
      dont_need_to!(pipeline,:ccf_total)
    end

    if has_cache(pipeline,:ccf_total) return read_cache(pipeline,:ccf_total)
    else   @error("Invalid pipeline state.")          end
end
