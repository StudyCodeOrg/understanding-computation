(ns ucomp.simple.big-step)

(defprotocol Expression
  (eval [this environment]))

(defrecord Num [value]
  Expression
  (eval [_ _] value))

(defrecord Bool [value]
  Expression
  (eval [_ _] value))

(defrecord Variable [name]
  Expression
  (eval [_ environment] (get environment name)))

(defrecord Add [left right]
  Expression
  (eval [_ environment]
    (+
     (eval left environment)
     (eval right environment))))

(defrecord Multiply [left right]
  Expression
  (eval [_ environment]
    (*
     (eval left environment)
     (eval right environment))))

(defrecord LessThan [left right]
  Expression
  (eval [_ environment]
    (<
     (eval left environment)
     (eval right environment))))

(defrecord Assign [name value]
  Expression
  (eval [_ environment]
    (assoc environment name (eval value environment))))

(defrecord DoNothing []
  Expression
  (eval [_ environment] environment))

(defrecord If [condition consequence alternative]
  Expression
  (eval [_ environment]
    (if (eval condition environment)
      (eval consequence environment)
      (eval alternative environment))))

(defrecord Sequence [items]
  Expression
  (eval [_ environment]
    (reduce
     (fn [acc x] (eval x acc)) environment items)))

(defrecord While [condition body]
  Expression
  (eval [_ environment]
    (loop [condition condition
           environment environment]
      (if (eval condition environment)
        (recur condition (eval body environment))
        environment))))
