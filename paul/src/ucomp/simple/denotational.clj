(ns ucomp.simple.denotational)

(defprotocol Expression
  (to-clojure [this]))

(defrecord Num [value]
  Expression
  (to-clojure [_] `(fn [e#] ~value)))

(defrecord Bool [value]
  Expression
  (to-clojure [_] `(fn [e#] ~value)))

(defrecord Variable [name]
  Expression
  (to-clojure [_] `(fn [e#] (get e# ~name))))

(defrecord Add [left right]
  Expression
  (to-clojure [_]
    (let [leftclj (to-clojure left)
          rightclj (to-clojure right)]
      `(fn [e#]
         (+ (~leftclj e#)
            (~rightclj e#))))))

(defrecord Multiply [left right]
  Expression
  (to-clojure [_]
    (let [leftclj (to-clojure left)
          rightclj (to-clojure right)]
      `(fn [e#]
         (* (~leftclj e#)
            (~rightclj e#))))))

(defrecord LessThan [left right]
  Expression
  (to-clojure [_]
    (let [leftclj (to-clojure left)
          rightclj (to-clojure right)]
      `(fn [e#]
         (< (~leftclj e#)
            (~rightclj e#))))))

(defrecord Assign [name value]
  Expression
  (to-clojure [_]
    `(fn [e#]
       (assoc e# ~name (~(to-clojure value) e#)))))

(defrecord DoNothing []
  Expression
  (to-clojure [_] `identity))

(defrecord If [condition consequence alternative]
  Expression
  (to-clojure [_]
    `(fn [e#]
       (if (~(to-clojure condition) e#)
         (~(to-clojure consequence) e#)
         (~(to-clojure alternative) e#)))))

(defrecord Sequence [items]
  Expression
  (to-clojure [_]
    (let [itemsclj (into [] (map to-clojure items))]
      `(fn [e#]
         (reduce (fn [e# f#] (f# e#)) e# ~itemsclj)))))

(defrecord While [condition body]
  Expression
  (to-clojure [_]
    `(fn [e#]
       (loop [condition# ~(to-clojure condition)
              body# ~(to-clojure body)
              environment# e#]
         (if (condition# environment#)
           (recur condition# body# (body# environment#))
           environment#)))))
