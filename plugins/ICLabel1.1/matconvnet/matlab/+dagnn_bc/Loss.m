classdef Loss < dagnn_bc.ElementWise
  properties
    loss = 'softmaxlog'
    ignoreAverage = false
    normalise = true
    opts = {}
  end

  properties (Transient)
    average = 0
    numAveraged = 0
  end

  methods
    function outputs = forward(obj, inputs, params)
      outputs{1} = vl_nnloss(inputs{1}, inputs{2}, [], 'loss', obj.loss, obj.opts{:}) ;
      obj.accumulateAverage(inputs, outputs);
    end

    function accumulateAverage(obj, inputs, outputs)
      if obj.ignoreAverage, return; end;
      n = obj.numAveraged ;
      m = n + size(inputs{1}, 1) *  size(inputs{1}, 2) * size(inputs{1}, 4);
      if obj.normalise
        obj.average = bsxfun(@plus, n * obj.average, size(inputs{1}, 4) * ...
          gather(outputs{1})) / m ;
      else
        obj.average = bsxfun(@plus, n * obj.average, gather(outputs{1})) / m ;
      end
      obj.numAveraged = m ;
    end

    function [derInputs, derParams] = backward(obj, inputs, params, derOutputs)
      derInputs{1} = vl_nnloss(inputs{1}, inputs{2}, derOutputs{1}, 'loss', obj.loss, obj.opts{:}) ;
      derInputs{2} = [] ;
      derParams = {} ;
    end

    function reset(obj)
      obj.average = 0 ;
      obj.numAveraged = 0 ;
    end

    function outputSizes = getOutputSizes(obj, inputSizes, paramSizes)
      outputSizes{1} = [1 1 1 inputSizes{1}(4)] ;
    end

    function rfs = getReceptiveFields(obj)
      % the receptive field depends on the dimension of the variables
      % which is not known until the network is run
      rfs(1,1).size = [NaN NaN] ;
      rfs(1,1).stride = [NaN NaN] ;
      rfs(1,1).offset = [NaN NaN] ;
      rfs(2,1) = rfs(1,1) ;
    end

    function obj = Loss(varargin)
      obj.load(varargin) ;
    end
  end
end
