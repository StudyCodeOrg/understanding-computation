(ns ucomp.simple.small-step)

(defprotocol Expression
  (reducible? [this])
  (reduce [this, environment]))

(defrecord Num [value]
  Expression
  (reducible? [_] false))

(defrecord Add [left right]
  Expression
  (reducible? [_] true)
  (reduce [this environment]
    (cond
      (reducible? left) (Add. (reduce left environment) right)
      (reducible? right) (Add. left (reduce right environment))
      :else (Num. (+ (:value left) (:value right))))))

(defrecord Multiply [left right]
  Expression
  (reducible? [_] true)
  (reduce [this environment]
    (cond
      (reducible? left) (Multiply. (reduce left environment) right)
      (reducible? right) (Multiply. left (reduce right environment))
      :else (Num. (* (:value left) (:value right))))))

(defrecord Bool [value]
  Expression
  (reducible? [_] false))

(defrecord LessThan [left, right]
  Expression
  (reducible? [_] true)
  (reduce [this environment]
    (cond
      (reducible? left) (LessThan. (reduce left environment) right)
      (reducible? right) (LessThan. left (reduce right environment))
      :else (Bool. (< (:value left) (:value right))))))


(defrecord GreaterThan [left, right]
  Expression
  (reducible? [_] true)
  (reduce [this environment]
    (cond
      (reducible? left) (LessThan. (reduce left environment) right)
      (reducible? right) (LessThan. left (reduce right environment))
      :else (Bool. (> (:value left) (:value right))))))

(defrecord Variable [name]
  Expression
  (reducible? [_] true)
  (reduce [this environment]
    (get environment name)))

(defrecord DoNothing []
  Expression
  (reducible? [_] false))

(defrecord Assign [name expression]
  Expression
  (reducible? [_] true)
  (reduce [this environment]
    (if (reducible? expression)
      [(Assign. name (reduce expression environment)) environment]
      [(DoNothing.) (merge environment {name expression})])))

(defrecord If [condition consequence alternative]
  Expression
  (reducible? [_] true)
  (reduce [this environment]
    (if (reducible? condition)
      [(If. (reduce condition environment) consequence alternative) environment]
      (if (= (Bool. true) condition)
        [consequence environment]
        [alternative environment]))))

(defrecord Sequence [first second]
  Expression
  (reducible? [_] true)
  (reduce [this environment]
    (if (= (DoNothing.) first)
      [second environment]
      (let [[reduced-first reduced-env] (reduce first environment)]
        [(Sequence. reduced-first second) reduced-env]))))

(defrecord While [condition body]
  Expression
  (reducible? [_] true)
  (reduce [this environment]
    [(If. condition (Sequence. body this) (DoNothing.)) environment]))

(defn run [statement environment]
  (let [statement (atom statement)
        environment (atom environment)]
    (while (reducible? @statement)
      (let [[next-stmt next-env] (reduce @statement @environment)]
        (do
          (prn @statement)
          (swap! statement (constantly next-stmt))
          (swap! environment (constantly next-env)))))
    [@statement @environment]))
