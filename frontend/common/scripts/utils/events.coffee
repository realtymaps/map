module.exports =
  targetInfo: (e) ->
    e.type +
      ' src:' + e.srcElement?.className?.slice?(0, 10) +
      ' tgt:' + e.target?.className?.slice?(0, 10) +
      ' to:' + e.toElement?.className?.slice?(0, 10) +
      ' frm:' + e.fromElement?.className?.slice?(0, 10) +
      ' rl:' + e.relatedTarget?.className?.slice?(0, 10)
