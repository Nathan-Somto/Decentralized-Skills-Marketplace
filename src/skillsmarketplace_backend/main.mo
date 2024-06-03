import Int "mo:base/Int";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Array "mo:base/Array";
actor DSkillsMarket{
  type Skill = {
  id: Text;
  freelancer: Principal;
  description: Text;
  price: Nat;
};

type Task = {
  id: Text;
  client: Principal;
  freelancer: Principal;
  description: Text;
  status: Text;
};

type Review = {
  id: Text;
  taskId: Text;
  client: Principal;
  freelancer: Principal;
  rating: Nat;
  feedback: Text;
};

type User = {
  id: Principal;
  name: Text;
  email: Text;
  skills: [Skill];
  tasks: [Task];
  reviews: [Review];
};
var skills: HashMap.HashMap<Text, Skill> = HashMap.HashMap<Text, Skill>(10, Text.equal, Text.hash);
var tasks: HashMap.HashMap<Text, Task> = HashMap.HashMap<Text, Task>(10, Text.equal, Text.hash);
var reviews: HashMap.HashMap<Text, Review> = HashMap.HashMap<Text, Review>(10, Text.equal, Text.hash);
var users: HashMap.HashMap<Principal, User> = HashMap.HashMap<Principal, User>(10, Principal.equal, Principal.hash);
public shared({caller}) func registerUser(name: Text, email: Text): async Bool {
    let userId = caller;
    let existingUser = users.get(userId);
    switch (existingUser) {
        case (null) {
            let user = {
                id = userId;
                name;
                email;
                skills = [];
                tasks = [];
                reviews = [];
            };
            users.put(userId, user);
            return true;
        };
        case (?_) { return false; };
    }
};

public shared({caller}) func addSkill(description: Text, price: Nat): async Text {
    let userId = caller;
    let existingUser = users.get(userId);
    switch (existingUser) {
        case (null) { return "User not registered"; };
        case (?user) {
            let skillId = "skill_" # Int.toText(Time.now());
            let skill = {
                id = skillId;
                freelancer = userId;
                description;
                price;
            };
            skills.put(skillId, skill);
             let updatedUser = {
                id = user.id;
                name = user.name;
                email = user.email;
                skills = Array.append<Skill>(user.skills, [skill]);
                tasks = user.tasks;
                reviews = user.reviews;
            };
            users.put(userId, updatedUser);
            return skillId;
        };
    }
};

public shared({caller}) func hireFreelancer(skillId: Text, description: Text): async Text {
    let userId = caller;
    let skill = skills.get(skillId);
    switch (skill) {
        case (null) { return "Skill not found"; };
        case (?s) {
            let taskId = "task_" # Int.toText(Time.now());
            let task = {
                id = taskId;
                client = userId;
                freelancer = s.freelancer;
                description;
                status = "open";
            };
            tasks.put(taskId, task);
            return taskId;
        };
    }
};

public shared({caller}) func completeTask(taskId: Text): async Bool {
    let task = tasks.get(taskId);
    switch (task) {
        case (null) { return false; };
        case (?t) {
            if (t.client == caller or t.freelancer == caller) {
                tasks.put(taskId, {t with status = "completed"});
                return true;
            } else {
                return false;
            }
        };
    }
};


public shared({caller}) func leaveReview(taskId: Text, rating: Nat, feedback: Text): async Text {
    let task = tasks.get(taskId);
    switch (task) {
        case (null) { return "Task not found"; };
        case (?t) {
            if (t.client == caller and t.status == "completed") {
                let reviewId = "review_" # Int.toText(Time.now());
                let review = {
                    id = reviewId;
                    taskId;
                    client = caller;
                    freelancer = t.freelancer;
                    rating;
                    feedback;
                };
                reviews.put(reviewId, review);
                return reviewId;
            } else {
                return "Only the client can leave a review after task completion";
            }
        };
    }
}
};